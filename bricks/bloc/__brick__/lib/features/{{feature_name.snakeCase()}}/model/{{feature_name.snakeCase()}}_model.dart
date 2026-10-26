/// Response model for {{feature_name.titleCase()}}.
///
/// Parse defensively (Golden Rule #12): never trust types from the wire.
class {{feature_name.pascalCase()}}Model {
  const {{feature_name.pascalCase()}}Model({
    required this.id,
    required this.name,
  });

  factory {{feature_name.pascalCase()}}Model.fromJson(Map<String, dynamic> json) {
    return {{feature_name.pascalCase()}}Model(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
    );
  }

  final String id;
  final String name;
}
