import 'package:dio/dio.dart';
import 'package:{{project_name}}/networking/api_base_helper.dart';

/// Repository for {{feature_name.titleCase()}}.
///
/// **Architecture Rules & Invariants:**
/// - Responsible ONLY for API transport and forwarding raw response to BLoC.
/// - NEVER call `Model.fromJson(...)` here. Parsing is the BLoC's responsibility.
/// - Accepts optional [CancelToken] for request aborts.
class {{feature_name.pascalCase()}}Repo {
  final ApiBaseHelper _api;

  {{feature_name.pascalCase()}}Repo({ApiBaseHelper? api})
      : _api = api ?? ApiBaseHelper.instance;

  // Example: Return raw JSON Map directly to BLoC
  // Future<Map<String, dynamic>> fetch{{feature_name.pascalCase()}}({CancelToken? cancelToken}) async {
  //   return await _api.get('/endpoint', cancelToken: cancelToken);
  // }
}
