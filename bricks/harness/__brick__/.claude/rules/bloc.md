---
paths:
  - "lib/**/bloc/*_bloc.dart"
  - "lib/**/bloc/*_event.dart"
  - "lib/**/bloc/*_state.dart"
---

# BLoC Architecture & Reactive State Rules

These rules apply whenever viewing, editing, or generating BLoC files.

## Golden Rules for State & Logic
1. **One BLoC, One Repo**: A BLoC never holds two repos. Compose shared capabilities with mixins (`with FooMixin`), never repository inheritance.
2. **BLoC Owns Logic and State**: Await repo transport calls, parse with `fromJson`, emit `ApiResponse<T>`.
3. **Zero RxDart Outside BLoC**: Widgets consume plain `Stream<T>` and `ApiResponse<T>`. Do not export RxDart subjects to the presentation layer.
4. **Subject Hygiene**:
   - Every subject must be closed in `dispose()`.
   - All stream emissions must be guarded against closed subjects:
     ```dart
     if (!_subject.isClosed) {
       _subject.add(data);
     }
     ```
   - Cancel subscriptions via `CompositeSubscription` or individual `StreamSubscription.cancel()`.
5. **Request Cancellation & Retries**:
   - Call `createNewToken()` before network operations in `fetch()`.
   - Catch and ignore `RequestCancelledException`.
   - Map failures to `ApiResponse.error(e, retry: fetch)`.
6. **Live Search**:
   - Use `PublishSubject<String>` chained with `.debounceTime(const Duration(milliseconds: 300)).distinct()`.
