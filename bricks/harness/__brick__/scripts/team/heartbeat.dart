// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';

/// Inspects swarm state, sessions, and active tasks across single/multi-session modes,
/// including human-in-the-loop blockers.
///
/// Usage:
///   dart run scripts/team/heartbeat.dart
void main() {
  final queueFile = File('.harness/tasks/active.json');
  var pending = 0;
  var inProgress = 0;
  var completed = 0;
  var waitingHuman = 0;
  var activeSessions = 0;
  final blockedTasks = <String>[];

  if (queueFile.existsSync()) {
    try {
      final data = jsonDecode(queueFile.readAsStringSync()) as Map<String, dynamic>;
      final tasks = (data['tasks'] as List<dynamic>? ?? <dynamic>[]).cast<Map<String, dynamic>>();
      final sessions = (data['sessions'] as List<dynamic>? ?? <dynamic>[]).cast<Map<String, dynamic>>();
      activeSessions = sessions.length;
      for (final t in tasks) {
        final status = t['status']?.toString();
        if (status == 'pending') pending++;
        if (status == 'in_progress') inProgress++;
        if (status == 'completed') completed++;
        if (status == 'waiting_human' || status == 'waiting_input') {
          waitingHuman++;
          final reason = t['blocked_reason'] ?? 'needs input';
          blockedTasks.add('${t['id']} (@${t['assignee']}): $reason');
        }
      }
    } catch (_) {}
  }

  final gitStatus = Process.runSync('git', ['status', '--short'], runInShell: true);
  final changedCount = (gitStatus.stdout as String)
      .split('\n')
      .where((l) => l.trim().isNotEmpty)
      .length;

  print(
    'Heartbeat: sessions=$activeSessions in_progress=$inProgress pending=$pending waiting_human=$waitingHuman completed=$completed | uncommitted_changes=$changedCount',
  );
  if (blockedTasks.isNotEmpty) {
    print('  Blocked on human:');
    for (final b in blockedTasks) {
      print('    - $b');
    }
  }
}
