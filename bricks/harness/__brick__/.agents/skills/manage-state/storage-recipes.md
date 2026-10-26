# Storage & Offline Cache Recipes

Production-tested patterns for local persistence, offline caching, and transparent cache-aside in the Flutter-RxDart-Base architecture.

---

## Recipe 1: Transparent Cache-Aside with Local Database (SQLite / Drift)

Combines the remote network repository with a local database cache. On screen open, the BLoC immediately displays the locally cached records while initiating a background fetch over Dio. Once fresh data arrives, it updates both the active stream and the local cache.

```dart
import 'dart:async';
import 'package:dio/dio.dart';

/// Mixin for repositories or services to cache raw response JSON locally.
mixin LocalCacheMixin {
  /// Loads cached JSON from local storage or database table.
  Future<Map<String, dynamic>?> readCache(String cacheKey);

  /// Saves fresh JSON response into local storage with a timestamp.
  Future<void> writeCache(String cacheKey, Map<String, dynamic> data);

  /// Checks if cached record is older than the given [maxAge].
  bool isStale(DateTime cachedAt, {Duration maxAge = const Duration(hours: 4)}) {
    return DateTime.now().difference(cachedAt) > maxAge;
  }
}

/// Feature repository using the cache-aside pattern.
class FeedRepo with LocalCacheMixin {
  final ApiBaseHelper _api = ApiBaseHelper.instance;

  @override
  Future<Map<String, dynamic>?> readCache(String cacheKey) async {
    // Read from local Drift database or shared preferences
    return null;
  }

  @override
  Future<void> writeCache(String cacheKey, Map<String, dynamic> data) async {
    // Persist raw JSON to local database
  }

  Future<Map<String, dynamic>> fetchFeed({CancelToken? cancelToken}) async {
    final response = await _api.get(
      ApiConstants.feedEndpoint,
      cancelToken: cancelToken,
    );
    await writeCache('feed_home', response);
    return response;
  }
}
```

### BLoC Dual-Emission Pattern (Cached then Fresh)

```dart
Future<void> fetchWithCache() async {
  final token = createNewToken();

  // 1. Emit cached content immediately if available
  final cached = await _repo.readCache('feed_home');
  if (cached != null) {
    _emit(ApiResponse.completed(FeedModel.fromJson(cached)));
  } else {
    _emit(const ApiResponse.loading());
  }

  // 2. Fetch fresh data over the network
  try {
    final fresh = await _repo.fetchFeed(cancelToken: token);
    _emit(ApiResponse.completed(FeedModel.fromJson(fresh)));
  } on RequestCancelledException {
    // Newer request superseded this one
  } on ApiException catch (e) {
    // Only show error if no cache was previously displayed
    if (_data.valueOrNull is! SuccessResponse) {
      _emit(ApiResponse.error(e, retry: fetchWithCache));
    }
  }
}
```

---

## Recipe 2: Key-Value Persistence with `LocalStorage`

For device preferences, draft form state, and onboarding flags (distinct from Redux session state).

```dart
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorage {
  LocalStorage._();
  static final LocalStorage instance = LocalStorage._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get hasSeenOnboarding => _prefs?.getBool('seen_onboarding') ?? false;

  Future<bool> setHasSeenOnboarding(bool value) async {
    return _prefs?.setBool('seen_onboarding', value) ?? false;
  }

  String? getDraft(String formKey) => _prefs?.getString('draft_$formKey');

  Future<void> saveDraft(String formKey, String jsonString) async {
    await _prefs?.setString('draft_$formKey', jsonString);
  }

  Future<void> clearDraft(String formKey) async {
    await _prefs?.remove('draft_$formKey');
  }
}
```

---

## Recipe 3: Offline Mutation Queue & Sync

Queues outgoing actions while offline, then replays them sequentially upon network reconnection.

```dart
import 'dart:collection';
import 'dart:async';

class OfflineSyncQueue {
  OfflineSyncQueue._();
  static final OfflineSyncQueue instance = OfflineSyncQueue._();

  final Queue<Map<String, dynamic>> _queue = Queue<Map<String, dynamic>>();
  bool _isFlushing = false;

  void enqueueMutation(Map<String, dynamic> payload) {
    _queue.add(payload);
  }

  Future<void> flush(Future<void> Function(Map<String, dynamic> item) execute) async {
    if (_isFlushing || _queue.isEmpty) return;
    _isFlushing = true;

    try {
      while (_queue.isNotEmpty) {
        final item = _queue.first;
        await execute(item);
        _queue.removeFirst();
      }
    } finally {
      _isFlushing = false;
    }
  }
}
```
