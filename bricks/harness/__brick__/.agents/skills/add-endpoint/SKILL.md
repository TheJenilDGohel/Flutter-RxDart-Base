---
name: add-endpoint
description: Connects a backend API endpoint to this Flutter Redux + RxDart + Dio app the architecture's way - contract from Postman/OpenAPI, ApiConstants entry, transport-only repo method on ApiBaseHelper, defensive Model.fromJson, BLoC call with cancellation and typed ApiException handling, tests with the real response. Use when asked to call, integrate, consume, add or change an API, endpoint, request, upload or response model, or when a response shape, status:false, 422 or parsing error comes up.
---

# Add or change an endpoint

The data path is fixed: `ApiConstants` → repo (transport) → BLoC (parse + state) → widget (render). Each layer has one job, and three of the 🔒 lint rules guard the boundaries.

## 0. Load what this project learned
1. Read `.harness/skills/add-endpoint.md` if it exists: backend quirks and conventions already discovered here. It wins over this file.
2. Check the Knowledge Graph (`search_nodes` / `read_graph`) or run `dart run scripts/agent/learn.dart list add-endpoint`.

## 1. Read the contract, don't guess it
Look for `*.postman_collection.json`, then OpenAPI/Swagger, then docs (`AGENTS.md` §3). Ingest contracts using `dart run scripts/agent/ingest_contract.dart <contract.json> --scaffold <endpoint>` to generate defensive models, endpoint constants, and create test fixtures in `test/fixtures/`. Write down the method, path and path params, query params, request body, **one real success response**, and the error shape. No real response → ask for one. Never infer field names or types from the endpoint's name.

Check the contract against what the base does to every call:
- A top-level JSON array comes back as `{'items': [...]}`. An empty body becomes `{}`. A non-JSON body throws `MalformedResponseException`.
- HTTP 200/201 with `{"status": false, "message": ...}` becomes `BusinessLogicException`, and that message is shown to users verbatim.
- `PlatformInjectorInterceptor` adds `"platform": "app"` to every JSON body. A strict backend that rejects unknown fields fails with 400.
- Only GET/HEAD/OPTIONS/PUT/DELETE are retried (twice). POST is never retried, so make writes idempotent on the server or guard against double taps in the BLoC.
- The bearer token goes only to the `BASE_URL` host (same scheme, host and port). A 401 while signed in dispatches `LogoutAction` by itself.

## 2. Endpoint constant
Add the endpoint to `lib/networking/api_constants.dart`, following the commented pattern there:

```dart
static String get ordersEndpoint => '$baseUrl/orders';
static String orderEndpoint(String id) => '$baseUrl/orders/$id';
```

A third-party absolute URL (CDN, presigned upload) is fine and never receives the token.

## 3. Repo method: transport only (rule 1 🔒)
```dart
Future<Map<String, dynamic>> fetchOrders({
  required int page,
  CancelToken? cancelToken,
}) {
  return _api.get(
    ApiConstants.ordersEndpoint,
    queryParameters: {'page': page},
    cancelToken: cancelToken,
  );
}
```
- Return the raw `Map<String, dynamic>`. Never call `fromJson`/`fromMap` here, not even as a tear-off. `repo_transport_only` fails the gate.
- Always accept and forward `CancelToken? cancelToken`.
- `ApiBaseHelper` methods: `get`, `post`, `put`, `delete`, and `postFormData` / `putFormData` (multipart, with an `onSendProgress` callback). Put `MultipartFile` values in the form map.
- There is no `patch`. If the backend needs PATCH, add a `patch` method to `ApiBaseHelper` that mirrors `put` exactly. That changes shared networking, so say so in your summary.
- Let exceptions propagate. The repo never catches.
- For complete production recipes (CRUD, parameter sanitization, capability mixins, multipart uploads, bulk fetches, binary downloads, cache-aside), see `.agents/skills/add-endpoint/repo-recipes.md`.

### Repository architecture & capability mixins
- **One BLoC, one repo**: A BLoC never holds two repository instances (e.g. `_inquiriesRepo` and `_agentsRepo`). That breaks 1:1 cohesion and doubles mock setup in tests.
- **Never extend another feature's repo**: `class InquiriesRepo extends AllAgentsRepo` is an anti-pattern. Inheritance leaks unrelated and sensitive endpoints (audit-logged OTP reveals, delete operations) into features that should not have access to them.
- **Compose shared endpoints with mixins**: When multiple features need a secondary capability (e.g. an agent dropdown for filtering, inquiry tags, profile fetch, logout), extract that capability into a `mixin`:

```dart
mixin AgentsListMixin {
  final ApiBaseHelper _api = ApiBaseHelper.instance;

  @protected
  ApiBaseHelper get api => _api;

  Future<Map<String, dynamic>> getAgents({
    int? page,
    int? limit,
    CancelToken? cancelToken,
  }) {
    final query = <String, dynamic>{
      if (page != null) 'page': page,
      if (limit != null) 'limit': limit,
    };
    return _api.get(
      ApiConstants.agentsEndpoint,
      queryParameters: query,
      cancelToken: cancelToken,
    );
  }
}
```

Then compose it onto the feature repo with `with`:
```dart
final class InquiriesRepo with AgentsListMixin {
  // Exposes getAgents() alongside its own inquiry methods
}
```
In tests, a single `FakeInquiriesRepo` extends or implements `InquiriesRepo` and overrides whatever the test exercises.

### Clean query & filter serialization
Never send empty strings or null keys (`?search=&status=&tag=`) to the backend. Use a private helper to build clean maps:

```dart
Map<String, dynamic> _filterParams(OrderFilter filter) {
  final query = <String, dynamic>{};
  if (filter.search.trim().isNotEmpty) query['search'] = filter.search.trim();
  if (filter.status != null && filter.status!.isNotEmpty) query['status'] = filter.status;
  if (filter.fromDate != null) {
    query['dateFrom'] = filter.fromDate!.toIso8601String().split('T').first;
  }
  return query;
}
```
Spread it into the query map: `queryParameters: {'page': page, 'limit': limit, ..._filterParams(filter)}`.

### Multipart file uploads
Use `postFormData` or `putFormData` with `MultipartFile.fromFile`:

```dart
Future<Map<String, dynamic>> updateProfile({
  required String name,
  File? avatar,
  CancelToken? cancelToken,
}) async {
  final data = <String, dynamic>{
    'name': name,
    if (avatar != null)
      'avatar': await MultipartFile.fromFile(
        avatar.path,
        filename: avatar.path.split(Platform.pathSeparator).last,
      ),
  };
  return _api.putFormData(
    ApiConstants.profileEndpoint,
    data: data,
    cancelToken: cancelToken,
  );
}
```

### Large fetches and timeout overrides (`all=true`)
When an endpoint supports dumping all rows for bulk selection or export (e.g. `all=true` dropping paging), the default 30s timeout might cut off the server. Override `receiveTimeout`:

```dart
Future<Map<String, dynamic>> getAllOrders({CancelToken? cancelToken}) {
  return _api.get(
    ApiConstants.ordersEndpoint,
    queryParameters: const {'all': 'true'},
    options: Options(receiveTimeout: const Duration(minutes: 5)),
    cancelToken: cancelToken,
  );
}
```

### Binary / non-JSON responses (PDF / file downloads)
When an endpoint returns raw bytes rather than JSON, access `_api.dio` directly with `ResponseType.bytes` and `validateStatus`:

```dart
Future<List<int>> downloadInvoicePdf(String id, {CancelToken? cancelToken}) async {
  final response = await _api.dio.get<List<int>>(
    ApiConstants.invoicePdfEndpoint(id),
    options: Options(
      responseType: ResponseType.bytes,
      validateStatus: (_) => true,
      receiveTimeout: const Duration(minutes: 5),
    ),
    cancelToken: cancelToken,
  );
  if (response.statusCode != null &&
      response.statusCode! >= 200 &&
      response.statusCode! < 300) {
    return response.data ?? const [];
  }
  throw BusinessLogicException('Failed to download invoice');
}
```


## 4. Model: defensive parsing (rule 12)
```dart
factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
  id: (json['id'] as num?)?.toInt() ?? 0,
  title: json['title']?.toString() ?? '',
  total: (json['total'] as num?)?.toDouble() ?? 0,
  placedAt: DateTime.tryParse(json['placed_at']?.toString() ?? ''),
  lines: (json['lines'] as List? ?? [])
      .whereType<Map<String, dynamic>>()
      .map(OrderLineModel.fromJson)
      .toList(),
);
```
- Never a bare `as String` / `as int` on wire data: one null or one `"12"` instead of `12` crashes the screen.
- Make a field nullable only when "absent" means something different from the default.
- Enums: map unknown values to an explicit fallback instead of throwing.
- Request bodies: the BLoC builds the map (or calls `model.toJson()`) and passes it to the repo.

## 5. BLoC call
- **Reads** mirror the generated `fetch({bool refresh = false})`. Call `createNewToken()` first, emit loading (unless refreshing over content), then `Model.fromJson`. Catch `RequestCancelledException` and do nothing. Catch `ApiException` and emit `ApiResponse.error(e, retry: fetch)`. Catch `Object` and wrap it in `MalformedResponseException`, never showing `e.toString()`.
- **Writes** (submit, delete, upload): guard double taps, don't auto-retry, and report the result through a state stream and/or a one-off event. The recipe is section A of `.agents/skills/manage-state/bloc-recipes.md`.
- **Several requests on one screen** share the BLoC's single cancel token. Calling `createNewToken()` in two independent methods cancels the other request. See section E of the recipes.

## 6. Tests with the real response
Copy the contract's success response into the BLoC test as a `const` map literal, then cover:
1. Real response → `SuccessResponse` with the fields parsed.
2. Missing and wrongly-typed fields → defaults, no throw.
3. `{'items': [...]}` when the endpoint returns a top-level array.
4. The relevant errors: a business error, a 422 message, a 404.

Use the generated `Fake<Feature>Repo` pattern. Details: `.agents/skills/write-tests/SKILL.md`.

## 7. Gate and close out
Run `dart run scripts/agent/on_edit.dart` on touched files while iterating, then `dart run scripts/agent/verify.dart` for the full gate before closing out per `AGENTS.md` §6. Record any backend quirk you found (date format, pagination style, an error field name) into the Knowledge Graph (`add_observations`), in `.claude/rules/endpoints.md`, or with `learn.dart add add-endpoint ...`, because the next endpoint on this backend will hit it too.

## Changing an existing endpoint
Find every caller first. Use the Dart MCP `lsp` references tool instead of regex or `grep` to find every usage of the repo method and the `ApiConstants` getter. Update the model and its tests together. When a field is removed, keep parsing tolerant until the backend change has shipped everywhere.
