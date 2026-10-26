import 'package:dio/dio.dart';
import 'package:{{project_name}}/networking/api_base_helper.dart';

/// Repository for {{feature_name.titleCase()}}.
///
/// **Golden Rule #1 — transport only:** call [ApiBaseHelper] and return the
/// raw `Map<String, dynamic>`. Parsing (`Model.fromJson`) belongs in the
/// BLoC; the `repo_transport_only` lint enforces this.
class {{feature_name.pascalCase()}}Repo {
  {{feature_name.pascalCase()}}Repo({ApiBaseHelper? api})
      : _api = api ?? ApiBaseHelper.instance;

  final ApiBaseHelper _api;

  Future<Map<String, dynamic>> fetch{{feature_name.pascalCase()}}({CancelToken? cancelToken}) {
    // TODO({{feature_name.snakeCase()}}): replace with the real endpoint from ApiConstants.
    return _api.get('/{{feature_name.paramCase()}}', cancelToken: cancelToken);
  }
}
