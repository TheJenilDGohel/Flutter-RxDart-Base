---
paths:
  - "lib/**/repo/**/*.dart"
  - "lib/**/*_repo.dart"
  - "lib/**/services/**/*.dart"
  - "lib/**/models/**/*.dart"
  - "lib/networking/**/*.dart"
---

# Networking, Transport & Model Rules

These rules apply when viewing, editing, or generating networking, services, repository, and model files.

## Golden Rules for Transport
1. **Repository is Transport Only**:
   - Repositories call `ApiBaseHelper` and return raw `Map<String, dynamic>`.
   - Never call `fromJson` or `fromMap` inside repository classes or files.
2. **Defensive Model Parsing**:
   - Guard against nulls and type mismatches:
     - `(json['id'] as num?)?.toInt() ?? 0`
     - `json['name']?.toString() ?? ''`
     - `(json['items'] as List? ?? []).map((e) => Model.fromJson(e as Map<String, dynamic>)).toList()`
     - `DateTime.tryParse(json['created_at']?.toString() ?? '')`
3. **Endpoint Registration**:
   - Register route constants in `lib/networking/api_constants.dart`.
   - Never hardcode endpoint URLs inside feature code.
4. **Auth & Interceptors**:
   - `AuthInterceptor` attaches the bearer token only to the base host.
   - Do not write manual 401 token handlers; 401 triggers store logout automatically.
5. **Repository Recipes**:
   - For complete recipes (CRUD, parameter sanitization, capability mixins, multipart uploads, bulk fetches, binary downloads, cache-aside), see `.agents/skills/add-endpoint/repo-recipes.md`.
