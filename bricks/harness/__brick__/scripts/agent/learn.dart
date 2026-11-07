// ignore_for_file: avoid_print

import 'dart:io';

/// The harness learning loop, one loop and no archive:
/// lesson → seen twice → a rule line or a lint → the lesson is deleted.
/// The store is `.harness/lessons.md`, plain Markdown any agent can read
/// without this script. The `evolve-harness` skill says when to use each
/// command.
///
/// ```
/// dart run scripts/agent/learn.dart list [scope]      # start of a task
/// dart run scripts/agent/learn.dart add <scope> <lesson...> [--proof <ref>] [--force]
/// dart run scripts/agent/learn.dart hit <id> [--proof <ref>]
/// dart run scripts/agent/learn.dart promote <id> <target>...   # deletes the lesson
/// dart run scripts/agent/learn.dart retire <id>
/// dart run scripts/agent/learn.dart prune             # deletes stale one-offs
/// dart run scripts/agent/learn.dart review            # what to promote or prune
/// dart run scripts/agent/learn.dart check             # format check (verify.dart)
/// ```
///
/// `<scope>` is a skill in `.agents/skills/` or `general`. A `<target>` is
/// `upstream` (printed as a proposal for the base repo) or the file that now
/// carries the rule (`AGENTS.md`, `.claude/rules/<domain>.md`, a skill's
/// `SKILL.md`). Promote only after the rule or lint exists: the lesson is
/// deleted, git keeps it. A repeat of a deleted lesson is a new lesson, and
/// its rule needs a lint.
///
/// Lessons are committed and loaded into future agents' context, so `add`
/// refuses (and `check` fails on) text that looks like a secret or an
/// injected instruction: memory must never carry either. `check` also scans
/// the other agent-written memory (overlays, specs, active context) for
/// credentials.
///
/// Deterministic and offline. `HARNESS_TODAY=YYYY-MM-DD` overrides the date.
void main(List<String> args) {
  final cli = _Args(args);
  final command = cli.positional.isEmpty ? 'help' : cli.positional.first;
  final rest = cli.positional.skip(1).toList();
  switch (command) {
    case 'list':
      _list(rest.firstOrNull);
    case 'add':
      _add(rest, cli);
    case 'hit':
      _hit(rest, cli);
    case 'promote':
      _promote(rest);
    case 'retire':
      _retire(rest);
    case 'prune':
      _prune();
    case 'review':
      _review();
    case 'check':
      _check();
    default:
      print(_usage);
      if (command != 'help') exitCode = 64;
  }
}

const _path = '.harness/lessons.md';

/// Seen this many times → ready to promote.
const _promoteAt = 2;

/// Seen once and not since → candidate for retirement.
const _staleDays = 90;

/// More active lessons than this means the loop isn't promoting or pruning.
const _activeCap = 30;

const _maxLength = 240;

const _usage = '''
Usage: dart run scripts/agent/learn.dart <command>
  list [scope]                       lessons for a skill (plus `general`)
  add <scope> <lesson...> [--proof <ref>] [--force]
  hit <id> [--proof <ref>]           the same lesson happened again
  promote <id> <target>...           the rule or lint exists: delete the lesson
  retire <id>                        wrong or obsolete: delete it
  prune                              delete lessons seen once and not in 90 days
  review                             what to promote, merge or prune
  check                              validate .harness/lessons.md''';

const _template = '''
# Lessons

<!-- Recorded by agents with scripts/agent/learn.dart (see the evolve-harness skill).
  One line per lesson:
    - [L<id>] <scope> (<hits>x, <YYYY-MM-DD>): <lesson> Proof: <ref>, <ref>
  Scope is a skill in .agents/skills/ or `general`. Prefer the CLI; hand edits
  must keep the format (verify.dart checks it). Seen twice = write the rule or lint, then promote (deletes it).
-->
''';

final _line = RegExp(
  r'^- \[L(\d+)\] ([a-z0-9]+(?:-[a-z0-9]+)*) \((\d+)x, (\d{4}-\d{2}-\d{2})\): '
  r'(.+?)(?: (Proof|Promoted to): (.+))?$',
);

// ── Commands ───────────────────────────────────────────────────────────

void _list(String? scope) {
  final book = _Book.load();
  if (scope != null) _requireScope(scope, warnOnly: true);
  final lessons =
      book.active
          .where(
            (l) => scope == null || l.scope == scope || l.scope == 'general',
          )
          .toList()
        ..sort(_byHits);
  final overlay = scope == null ? null : File('.harness/skills/$scope.md');
  if (overlay != null && overlay.existsSync()) {
    print('Project overlay: ${overlay.path} (read it; it wins over the skill)');
  }
  if (lessons.isEmpty) {
    print(
      scope == null ? 'No lessons recorded yet.' : 'No lessons for $scope yet.',
    );
    return;
  }
  for (final l in lessons) {
    print('L${l.id} (${l.hits}x) ${l.scope}: ${l.text}');
  }
}

void _add(List<String> rest, _Args cli) {
  if (rest.length < 2) _fail('usage: learn.dart add <scope> <lesson...>');
  final scope = rest.first;
  _requireScope(scope);
  final text = rest.skip(1).join(' ').trim();
  if (text.contains('\n')) _fail('A lesson is one line.');
  if (text.length > _maxLength) {
    _fail(
      'Lesson is ${text.length} characters; keep it under $_maxLength. '
      'State the trigger and the fix, not the story.',
    );
  }
  if (text.contains(' Proof: ') || text.contains(' Promoted to: ')) {
    _fail('Pass references with --proof, not inside the lesson text.');
  }
  for (final value in [text, ...cli.proofs]) {
    final unsafe = _unsafe(value);
    if (unsafe != null) {
      _fail(
        'Refused: the lesson $unsafe. Lessons are committed and loaded into '
        'every future agent\'s context — describe the fix, never the secret, '
        'and record only what you verified yourself or the user told you.',
      );
    }
  }

  final book = _Book.load();
  if (book.active.length >= _activeCap) {
    _fail(
      '${book.active.length} active lessons (cap $_activeCap). Promote the '
      'ones seen twice (`learn.dart review`) or `learn.dart prune` first.',
    );
  }
  if (!cli.force) {
    for (final l in book.active) {
      if (_similarity(l.text, text) >= 0.6) {
        _fail(
          'Looks like L${l.id}: "${l.text}"\n'
          'If it is the same lesson: learn.dart hit L${l.id} --proof <ref>. '
          'Otherwise re-run with --force.',
        );
      }
    }
  }
  final lesson = _Lesson(
    id: book.nextId,
    scope: scope,
    hits: 1,
    date: _today(),
    text: text,
    refs: cli.proofs,
  );
  book.active.add(lesson);
  book.save();
  print('Recorded L${lesson.id} ($scope).');
}

void _hit(List<String> rest, _Args cli) {
  if (rest.isEmpty) _fail('usage: learn.dart hit <id> [--proof <ref>]');
  final book = _Book.load();
  final id = _parseId(rest.first);
  final lesson = book.find(book.active, id);
  if (lesson == null) {
    _fail('No lesson L$id (a promoted lesson is deleted: record it again).');
  }
  lesson
    ..hits += 1
    ..date = _today()
    ..refs = _lastRefs([...lesson.refs, ...cli.proofs]);
  book.save();
  final ready = lesson.hits >= _promoteAt
      ? ' Ready to promote — write the rule line or lint, then '
            '`learn.dart promote L$id <target>`.'
      : '';
  print('L$id seen ${lesson.hits} times.$ready');
}

void _promote(List<String> rest) {
  if (rest.length < 2) {
    _fail(
      'usage: learn.dart promote <id> <target>...  (target: upstream or the '
      'file that now carries the rule, such as AGENTS.md or '
      '.claude/rules/<domain>.md)',
    );
  }
  final book = _Book.load();
  final id = _parseId(rest.first);
  final lesson = book.find(book.active, id);
  if (lesson == null) _fail('No lesson L$id.');
  final targets = rest.skip(1).toList();
  for (final target in targets) {
    final file = target.split('#').first;
    if (target != 'upstream' && !File(file).existsSync()) {
      _fail(
        'Target $target does not exist. Write the rule into it first, then '
        'promote: the lesson is deleted.',
      );
    }
  }
  book.active.remove(lesson);
  book.save();
  print('Promoted L$id → ${targets.join(', ')}; the lesson is deleted.');
  if (targets.contains('upstream')) {
    print('Proposal for the base repository: [${lesson.scope}] ${lesson.text}');
  }
}

void _retire(List<String> rest) {
  if (rest.isEmpty) _fail('usage: learn.dart retire <id>');
  final book = _Book.load();
  final id = _parseId(rest.first);
  final lesson = book.find(book.active, id);
  if (lesson == null) _fail('No lesson L$id.');
  book.active.remove(lesson);
  book.save();
  print('Retired L$id.');
}

void _prune() {
  final book = _Book.load();
  final today = DateTime.parse(_today());
  final stale = book.active.where((l) => _isStale(l, today)).toList();
  if (stale.isEmpty) {
    print('Nothing to prune.');
    return;
  }
  book.active.removeWhere(stale.contains);
  book.save();
  for (final l in stale) {
    print('Pruned L${l.id} (${l.date}) ${l.scope}: ${l.text}');
  }
}

/// Seen once and not since: a one-off, not a pattern.
bool _isStale(_Lesson l, DateTime today) {
  final seen = DateTime.tryParse(l.date);
  return l.hits == 1 && seen != null && today.difference(seen).inDays > _staleDays;
}

void _review() {
  final book = _Book.load();
  final skills = _skills();
  final today = DateTime.parse(_today());
  var todo = 0;

  print('Lessons: ${book.active.length} active (cap $_activeCap).');

  final ready = book.active.where((l) => l.hits >= _promoteAt).toList()
    ..sort(_byHits);
  if (ready.isNotEmpty) {
    todo++;
    print('\nReady to promote (seen $_promoteAt+ times):');
    for (final l in ready) {
      final target = l.scope == 'general'
          ? 'AGENTS.md §7 (below the project-rules marker)'
          : '.harness/skills/${l.scope}.md';
      print(
        '  L${l.id} (${l.hits}x) ${l.scope}: ${l.text}\n'
        '      → $target',
      );
    }
  }

  final pairs = <String>[];
  for (var i = 0; i < book.active.length; i++) {
    for (var j = i + 1; j < book.active.length; j++) {
      final a = book.active[i], b = book.active[j];
      if (_similarity(a.text, b.text) >= 0.4) {
        pairs.add('  L${a.id} ≈ L${b.id}: keep one (hit it), retire the other');
      }
    }
  }
  if (pairs.isNotEmpty) {
    todo++;
    print('\nPossible duplicates:');
    pairs.forEach(print);
  }

  final stale = book.active.where((l) => _isStale(l, today)).toList();
  if (stale.isNotEmpty) {
    todo++;
    print(
      '\nSeen once, not in $_staleDays days (`learn.dart prune` deletes '
      'them):',
    );
    for (final l in stale) {
      print('  L${l.id} (${l.date}) ${l.scope}: ${l.text}');
    }
  }

  final orphans = book.active
      .where((l) => skills != null && !_validScope(l.scope, skills))
      .toList();
  if (orphans.isNotEmpty) {
    todo++;
    print(
      '\nScope has no skill any more (re-add under another scope or '
      'retire):',
    );
    for (final l in orphans) {
      print('  L${l.id} ${l.scope}: ${l.text}');
    }
  }

  if (book.active.length > _activeCap) {
    todo++;
    print(
      '\n${book.active.length} active lessons (cap $_activeCap): '
      '`add` is refused until you promote or prune.',
    );
  }

  print(
    todo == 0
        ? '\nNothing to promote or prune.'
        : '\nNext: follow the evolve-harness skill for each item.',
  );
}

void _check() {
  final leaks = _memoryLeaks();
  if (leaks.isNotEmpty) {
    leaks.forEach(stderr.writeln);
    stderr.writeln(
      'Agent memory is loaded into every future session: remove these '
      '(and from git history) and rotate the credentials.',
    );
    exitCode = 1;
    return;
  }
  final file = File(_path);
  if (!file.existsSync()) {
    print('No lessons file yet ($_path is created by the first `add`).');
    return;
  }
  final book = _Book.parse(file.readAsStringSync());
  final errors = [...book.errors];
  final seen = <int>{};
  for (final l in book.active) {
    if (!seen.add(l.id)) errors.add('$_path: duplicate id L${l.id}');
    if (DateTime.tryParse(l.date) == null) {
      errors.add('$_path: L${l.id} has an invalid date ${l.date}');
    }
  }
  for (final l in book.active) {
    final unsafe = _unsafe('${l.text} ${l.refs.join(' ')}');
    if (unsafe != null) {
      errors.add('$_path: L${l.id} $unsafe; remove it (git history too)');
    }
  }
  if (errors.isNotEmpty) {
    errors.forEach(stderr.writeln);
    stderr.writeln(
      'Fix the lines above (format: see the comment at the top of $_path).',
    );
    exitCode = 1;
    return;
  }
  final ready = book.active.where((l) => l.hits >= _promoteAt).length;
  final skills = _skills();
  final orphans = book.active
      .where((l) => skills != null && !_validScope(l.scope, skills))
      .length;
  final notes = [
    if (ready > 0) '$ready ready to promote',
    if (orphans > 0) '$orphans with a missing skill',
    if (book.active.length > _activeCap) 'over the cap of $_activeCap',
  ];
  print(
    'Lessons OK: ${book.active.length} active.'
    '${notes.isEmpty ? '' : ' ${notes.join(', ')} — run `dart run '
              'scripts/agent/learn.dart review`.'}',
  );
}

// ── Store ──────────────────────────────────────────────────────────────

class _Lesson {
  _Lesson({
    required this.id,
    required this.scope,
    required this.hits,
    required this.date,
    required this.text,
    required this.refs,
  });

  final int id;
  final String scope;
  int hits;
  String date;
  final String text;

  List<String> refs;

  String format() {
    final tail = refs.isEmpty ? '' : ' Proof: ${refs.join(', ')}';
    return '- [L$id] $scope (${hits}x, $date): $text$tail';
  }
}

class _Book {
  _Book(this.header, this.tail);

  final String header;
  final String tail;
  final active = <_Lesson>[];

  /// Legacy `## Promoted` section: read, never written back.
  final promoted = <_Lesson>[];
  final errors = <String>[];

  int get nextId =>
      [...active, ...promoted].fold(0, (m, l) => l.id > m ? l.id : m) + 1;

  _Lesson? find(List<_Lesson> list, int id) =>
      list.where((l) => l.id == id).firstOrNull;

  static _Book load() {
    final file = File(_path);
    final book = _Book.parse(file.existsSync() ? file.readAsStringSync() : '');
    if (book.errors.isNotEmpty) {
      book.errors.forEach(stderr.writeln);
      _fail('Fix $_path first (or run `learn.dart check`).');
    }
    return book;
  }

  /// Sections: everything before `## Active` is a free header; anything
  /// after an unknown `## ` heading is a free tail. Both are kept verbatim.
  static _Book parse(String content) {
    final lines = content.replaceAll('\r\n', '\n').split('\n');
    final headerLines = <String>[], tailLines = <String>[];
    final active = <(int, String)>[], promoted = <(int, String)>[];
    var section = content.trim().isEmpty ? 'empty' : 'header';
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final heading = line.startsWith('## ') ? line.trim() : null;
      if (section != 'tail' && heading == '## Active') {
        section = 'active';
      } else if (section != 'tail' && heading == '## Promoted') {
        section = 'promoted';
      } else if (heading != null && section != 'header') {
        section = 'tail';
        tailLines.add(line);
      } else if (section == 'header') {
        headerLines.add(line);
      } else if (section == 'tail') {
        tailLines.add(line);
      } else if (section == 'active') {
        active.add((i + 1, line));
      } else if (section == 'promoted') {
        promoted.add((i + 1, line));
      }
    }
    final kept = headerLines.join('\n').trim();
    final header = section == 'empty'
        ? _template
        : (kept.isEmpty ? '' : '$kept\n');
    final book = _Book(header, tailLines.join('\n').trim());
    for (final (entries, into) in [
      (active, book.active),
      (promoted, book.promoted),
    ]) {
      for (final (number, line) in entries) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed == '_None yet._') continue;
        final m = _line.firstMatch(trimmed);
        if (m == null) {
          book.errors.add('$_path:$number: not a lesson line: $trimmed');
          continue;
        }
        into.add(
          _Lesson(
            id: int.parse(m[1]!),
            scope: m[2]!,
            hits: int.parse(m[3]!),
            date: m[4]!,
            text: m[5]!,
            refs: m[7] == null
                ? []
                : m[7]!
                      .split(',')
                      .map((r) => r.trim())
                      .where((r) => r.isNotEmpty)
                      .toList(),
          ),
        );
      }
    }
    return book;
  }

  void save() {
    final body = active.isEmpty
        ? '_None yet._'
        : ([...active]..sort((a, b) => a.id.compareTo(b.id)))
              .map((l) => l.format())
              .join('\n');
    final out = StringBuffer();
    if (header.isNotEmpty) out.write('$header\n');
    out.write('## Active\n$body\n');
    if (tail.isNotEmpty) out.write('\n$tail\n');
    File(_path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(out.toString());
  }
}

// ── Helpers ────────────────────────────────────────────────────────────

class _Args {
  _Args(List<String> args) {
    for (var i = 0; i < args.length; i++) {
      final a = args[i];
      if (a == '--force') {
        force = true;
      } else if (a == '--proof' && i + 1 < args.length) {
        proofs.add(args[++i].trim());
      } else if (a.startsWith('--proof=')) {
        proofs.add(a.substring('--proof='.length).trim());
      } else {
        positional.add(a);
      }
    }
  }

  final positional = <String>[];
  final proofs = <String>[];
  bool force = false;
}

/// Skill names in `.agents/skills/`, or null when there is no such folder.
Set<String>? _skills() {
  final dir = Directory('.agents/skills');
  if (!dir.existsSync()) return null;
  return dir
      .listSync()
      .whereType<Directory>()
      .where((d) => File('${d.path}/SKILL.md').existsSync())
      .map((d) => d.uri.pathSegments.where((s) => s.isNotEmpty).last)
      .toSet();
}

bool _validScope(String scope, Set<String> skills) =>
    scope == 'general' || skills.contains(scope);

void _requireScope(String scope, {bool warnOnly = false}) {
  final skills = _skills();
  final wellFormed = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch(scope);
  if (wellFormed && (skills == null || _validScope(scope, skills))) return;
  final sorted = (skills ?? <String>{}).toList()..sort();
  final known = ['general', ...sorted].join(', ');
  final message = 'Unknown scope "$scope". Use one of: $known.';
  if (warnOnly) {
    stderr.writeln(message);
  } else {
    _fail(message);
  }
}

int _parseId(String raw) {
  final m = RegExp(r'^[Ll]?(\d+)$').firstMatch(raw.trim());
  if (m == null) _fail('Not a lesson id: $raw (expected L7 or 7).');
  return int.parse(m[1]!);
}

int _byHits(_Lesson a, _Lesson b) =>
    b.hits != a.hits ? b.hits.compareTo(a.hits) : a.id.compareTo(b.id);

/// Keeps the three most recent references.
List<String> _lastRefs(List<String> refs) {
  final unique = <String>[];
  for (final r in refs.reversed) {
    if (r.isNotEmpty && !unique.contains(r)) unique.add(r);
  }
  return unique.take(3).toList().reversed.toList();
}

/// Unambiguous credentials: never allowed in any agent memory file.
final _credentials = <RegExp, String>{
  RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY'): 'contains a private key',
  RegExp(r'\bBearer\s+[A-Za-z0-9._~+/=-]{16,}'): 'contains a bearer token',
  RegExp(r'\beyJ[A-Za-z0-9_-]{8,}\.[A-Za-z0-9_-]{8,}\.'): 'contains a JWT',
  RegExp(r'\b(?:AKIA|ASIA)[0-9A-Z]{16}\b'): 'contains an AWS key',
  RegExp(r'\bgh[pousr]_[A-Za-z0-9]{30,}'): 'contains a GitHub token',
  RegExp(r'\bAIza[0-9A-Za-z_-]{35}\b'): 'contains a Google API key',
  RegExp(r'\b(?:sk|pk|rk)[-_](?:live|test|proj|ant)[-_][A-Za-z0-9_-]{8,}'):
      'contains an API key',
  RegExp(r'\bxox[abposr]-[A-Za-z0-9-]{10,}'): 'contains a Slack token',
  RegExp(r'[a-z][a-z0-9+.-]*://[^/\s:@]+:[^/\s@]+@'):
      'contains a URL with credentials',
};

/// Also refused in lessons, which are one-line rules: a secret assignment
/// or prompt-injection phrasing has no business there.
final _lessonOnly = <RegExp, String>{
  RegExp(
    r'\b(?:password|passwd|secret|api[_-]?key|access[_-]?token)\s*[:=]\s*\S{6,}',
    caseSensitive: false,
  ): 'assigns a secret value',
  RegExp(
    r'\b(?:ignore|disregard|override)\b.{0,30}\b(?:previous|prior|above|all|'
    r'system)\b.{0,20}\b(?:instructions?|rules?|prompts?)\b',
    caseSensitive: false,
  ): 'reads like an injected instruction',
};

/// Why [text] must not be stored, or null when it is fine. Outside lessons
/// ([lesson] false) only [_credentials] count: a spec may well say
/// `password: string`.
String? _unsafe(String text, {bool lesson = true}) {
  for (final patterns in [_credentials, if (lesson) _lessonOnly]) {
    for (final MapEntry(key: pattern, value: reason) in patterns.entries) {
      if (pattern.hasMatch(text)) return reason;
    }
  }
  return null;
}

/// Credentials in the other memory files agents write.
List<String> _memoryLeaks() {
  final files = [
    File('.harness/active-context.md'),
    File('.harness/progress.md'),
    for (final dir in ['.harness/skills', '.harness/specs'])
      if (Directory(dir).existsSync())
        ...Directory(
          dir,
        ).listSync().whereType<File>().where((f) => f.path.endsWith('.md')),
  ];
  final leaks = <String>[];
  for (final file in files.where((f) => f.existsSync())) {
    final lines = file.readAsLinesSync();
    for (var i = 0; i < lines.length; i++) {
      final reason = _unsafe(lines[i], lesson: false);
      if (reason != null) leaks.add('${file.path}:${i + 1}: $reason');
    }
  }
  return leaks;
}

const _stopWords = {
  'the',
  'and',
  'for',
  'with',
  'not',
  'use',
  'when',
  'from',
  'this',
  'that',
  'into',
  'are',
  'was',
  'its',
  'you',
  'your',
  'then',
  'than',
  'never',
  'always',
  'must',
  'should',
  'instead',
  'before',
  'after',
  'only',
};

Set<String> _words(String text) => RegExp(r'[a-z0-9_]+')
    .allMatches(text.toLowerCase())
    .map((m) => m[0]!)
    .where((w) => w.length >= 3 && !_stopWords.contains(w))
    .toSet();

/// Jaccard similarity of content words: catches re-recorded lessons, not
/// paraphrases (agents run `list` first and use `hit` for those).
double _similarity(String a, String b) {
  final wa = _words(a), wb = _words(b);
  if (wa.isEmpty || wb.isEmpty) return 0;
  return wa.intersection(wb).length / wa.union(wb).length;
}

String _today() {
  final override = Platform.environment['HARNESS_TODAY'];
  if (override != null && DateTime.tryParse(override) != null) {
    return override;
  }
  final now = DateTime.now();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${now.year}-${two(now.month)}-${two(now.day)}';
}

Never _fail(String message) {
  stderr.writeln(message);
  exit(1);
}
