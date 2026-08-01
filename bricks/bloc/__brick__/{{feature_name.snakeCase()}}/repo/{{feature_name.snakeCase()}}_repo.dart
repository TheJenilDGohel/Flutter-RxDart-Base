import 'package:{{project_name}}/networking/api_base_helper.dart';

/// Repository for {{feature_name.titleCase()}}.
///
/// Encapsulates data fetching and network operations for {{feature_name.titleCase()}}.
/// Uses constructor injection with [ApiBaseHelper.instance] fallback.
class {{feature_name.pascalCase()}}Repo {
  final ApiBaseHelper _api;

  {{feature_name.pascalCase()}}Repo({ApiBaseHelper? api})
      : _api = api ?? ApiBaseHelper.instance;

  // Add data fetch methods using _api.get(), _api.post(), etc.
}
