# API layer reference

## Interceptor chain (fixed order, `lib/networking/dio_client.dart`)
1. `ConnectivityInterceptor` — fails fast with `NoInternetException` when offline, before a
   request ever hits the wire.
2. `AuthInterceptor` — injects `Authorization: Bearer <AppStore.authToken>` for requests to the
   `BASE_URL` host only.
3. `PlatformInjectorInterceptor` — adds `{"platform": "app"}` to JSON bodies.
4. `RetryInterceptor` (`dio_smart_retry`) — retries transient failures of idempotent methods
   only (GET/HEAD/OPTIONS/PUT/DELETE), twice, at 1 s and 3 s.
5. `ErrorMappingInterceptor` — the last line of defense: maps any remaining `DioException` into
   one of the sealed `ApiException` subtypes below, so nothing above the networking layer ever
   sees a raw `DioException`.

## `ApiException` subtypes (`lib/networking/api_exceptions.dart`)
`NoInternetException`, `BadRequestException` (400), `UnauthorizedException` (401 — also logs
the user out), `ForbiddenException` (403), `NotFoundException` (404), `ConflictException`
(409), `RequestTimeoutException` (408 / Dio timeouts), `ValidationException` (422, carries the
server message), `TooManyRequestsException` (429), `InternalServerErrorException` (5xx and
unknown), `BusinessLogicException` (HTTP 200 with `{"status": false}`),
`MalformedResponseException` (body is not JSON), `RequestCancelledException`. Each has
`message` and, for HTTP errors, `statusCode`. The hierarchy is sealed — when you switch on
it, match exhaustively instead of a catch-all that hides new cases.

## `ApiResponse<T>` (`lib/networking/api_response.dart`)
Sealed: `InitialResponse`, `LoadingResponse`, `SuccessResponse(T data)`,
`ErrorResponse(ApiException error, {RetryCallback? retry})`. A BLoC subject is
`BehaviorSubject<ApiResponse<T>>` seeded with `ApiResponse.initial()`.

## Adding a new endpoint
1. Add the path to `lib/networking/api_constants.dart`.
2. Add a method to the feature's repo that calls `ApiBaseHelper` and returns raw `Map<String, dynamic>` —
   let exceptions propagate. (Golden Rule #1: NEVER call `Model.fromJson` in the repository).
3. Call it from the BLoC's `fetch({bool refresh = false})`: `createNewToken()`, emit
   `ApiResponse.loading()`, parse with `Model.fromJson`, emit `ApiResponse.completed(model)`;
   on `RequestCancelledException` do nothing; on other `ApiException`s emit
   `ApiResponse.error(e, retry: fetch)`. The bloc brick generates exactly this.
4. Don't add per-endpoint error handling inside widgets — that's what
   `exception.userFacingMessage` and `AppErrorState` are for.
