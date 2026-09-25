# API layer reference

## Interceptor chain (fixed order, `lib/networking/dio_client.dart`)
1. `ConnectivityInterceptor` — fails fast with `NoInternetException` when offline, before a
   request ever hits the wire.
2. `AuthInterceptor` — reads the token from `AppStore.authToken` and injects the auth header.
3. `PlatformInjectorInterceptor` — adds platform/device headers or body fields every request
   needs.
4. `RetryInterceptor` (from `dio_smart_retry`) — retries transient failures.
5. `ErrorMappingInterceptor` — the last line of defense: maps any remaining `DioException` into
   one of the sealed `ApiException` subtypes below, so nothing above the networking layer ever
   sees a raw `DioException`.

## `ApiException` subtypes (`lib/networking/api_exceptions.dart`)
`NoInternetException`, `BadRequestException`, `UnauthorizedException`, `NotFoundException`,
`ConflictException`, `RequestTimeoutException`, `InternalServerErrorException`,
`BusinessLogicException`. It's a sealed hierarchy — when you handle it (e.g. in a `switch` for
custom per-error UI), match exhaustively rather than adding a generic `catch`/`default` that
swallows a case silently.

## `ApiResponse<T>` (`lib/networking/api_response.dart`)
Sealed: `InitialResponse`, `LoadingResponse`, `SuccessResponse(T data)`, `ErrorResponse(dynamic error, {VoidCallback? retry})`. A bloc's
subject should always be typed `BehaviorSubject<ApiResponse<T>>`, seeded with `ApiResponse.initial()`.

## Adding a new endpoint
1. Add the path to `lib/networking/api_constants.dart`.
2. Add a method to the feature's repo that calls `ApiBaseHelper` and returns raw `Map<String, dynamic>` —
   let exceptions propagate. (Golden Rule #1: NEVER call `Model.fromJson` in the repository).
3. Call it from the bloc, parsing with `Model.fromJson` and emitting states: emit `ApiResponse.loading()` before the call,
   `ApiResponse.completed(model)` on success, `ApiResponse.error(e, retry: ...)` in the `catch`.
4. Don't add per-endpoint error handling inside widgets — that's what
   `exception.userFacingMessage` and `AppErrorState` are for.
