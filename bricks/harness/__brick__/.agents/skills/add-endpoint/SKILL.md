---
name: add-endpoint
description: Connects a backend API endpoint to this Flutter Redux + RxDart + Dio app the architecture's way - contract from Postman/OpenAPI, ApiConstants entry, transport-only repo method on ApiBaseHelper, defensive Model.fromJson, BLoC call with cancellation and typed ApiException handling, tests with the real response. Use when asked to call, integrate, consume, add or change an API, endpoint, request, upload or response model, or when a response shape, status:false, 422 or parsing error comes up.
---

# Add or change an endpoint

The data path is fixed: `ApiConstants` → repo (transport, rule 1) → BLoC (parse + state, rules 2 and 8) → widget (render). `AGENTS.md` §2-3 holds the rules; this skill holds the steps and the base's wire behaviour.

## 0. Load what this project learned
Read `.harness/skills/add-endpoint.md` if it exists (it wins over this file) and run `dart run scripts/agent/learn.dart list add-endpoint`.

## 1. Read the contract, don't guess it
Find the contract (`AGENTS.md` §3) and run `dart run scripts/agent/ingest_contract.dart <contract.json> --scaffold <endpoint>` for the model, constant and test fixture. Write down method, path and query params, body, **one real success response** and the error shape. No real response → ask. Never infer fields from the endpoint name.

What the base does to every call:
- A top-level JSON array arrives as `{'items': [...]}`; an empty body as `{}`; a non-JSON body throws `MalformedResponseException`.
- HTTP 200/201 with `{"status": false, "message": ...}` becomes `BusinessLogicException`; the message is shown verbatim.
- `PlatformInjectorInterceptor` adds `"platform": "app"` to every JSON body; a strict backend answers 400.
- Only GET/HEAD/OPTIONS/PUT/DELETE retry (twice). POST never does: guard double taps in the BLoC.
- Token and 401 handling: rule 11. Third-party absolute URLs (CDN, presigned upload) never get the token.

## 2. Constant and repo method
Add `static String get ordersEndpoint => '$baseUrl/orders';` (or `orderEndpoint(String id)`) to `lib/networking/api_constants.dart`, then:

```dart
Future<Map<String, dynamic>> fetchOrders({required int page, CancelToken? cancelToken}) =>
    _api.get(ApiConstants.ordersEndpoint, queryParameters: {'page': page}, cancelToken: cancelToken);
```
- Always forward `CancelToken? cancelToken`; never catch, let exceptions propagate.
- `ApiBaseHelper` has `get`, `post`, `put`, `delete`, `postFormData` / `putFormData` (multipart, `onSendProgress`). No `patch`: add one mirroring `put` and flag the shared-networking change in your summary.
- Recipes in `.agents/skills/add-endpoint/repo-recipes.md`: A list + detail, B clean filter params (no empty keys), C capability mixins, D multipart, E `all=true` with a longer `receiveTimeout`, F binary download, G cache-aside, H silent refresh, I native HTTP stack (opt-in, with its costs).

## 3. Model
Rule 12 idioms; lists as `(switch (json['lines']) { final List<Object?> v => v, _ => const <Object?>[] }).whereType<Map<String, dynamic>>().map(LineModel.fromJson).toList()`. Never a bare `as` cast on wire data (`as int`, `as num?`, `as List?`, `as Map?`): it throws on a wrong type instead of falling back. Nullable only when "absent" differs from the default; unknown enum values map to a fallback. Request bodies are built in the BLoC (map or `toJson()`).

## 4. BLoC call
- **Reads**: rule 8. Catch `ApiException` → `ApiResponse.error(e, retry: fetch)`; any other `Object` → wrap in `MalformedResponseException`.
- **Writes**: no auto-retry, guard double taps, report via state stream or one-off event: section A of `.agents/skills/manage-state/bloc-recipes.md`.
- **Several requests on one screen** share one cancel token; section E of the same file.

## 5. Tests with the real response
Paste the success response into the BLoC test as a `const` map and cover: real response parsed; missing or wrongly typed fields → defaults; `{'items': [...]}` for array endpoints; a business error, a 422 and a 404. Fake repo pattern: `.agents/skills/write-tests/SKILL.md`.

## 6. Gate
`on_edit.dart` while iterating, `verify.dart` at the end. Record backend quirks (date format, paging style, error field) in `.claude/rules/endpoints.md` or `learn.dart add add-endpoint ...`.

## Changing an existing endpoint
Find every caller of the repo method and the `ApiConstants` getter with the Dart MCP `lsp` references tool. Update model and tests together; keep parsing tolerant of a removed field until the backend change ships everywhere.
