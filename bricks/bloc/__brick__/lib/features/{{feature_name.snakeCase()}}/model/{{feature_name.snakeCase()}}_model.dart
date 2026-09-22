class {{feature_name.pascalCase()}}Model {
  final String id;
  final String name;

  const {{feature_name.pascalCase()}}Model({
    required this.id,
    required this.name,
  });

  factory {{feature_name.pascalCase()}}Model.fromJson(Map<String, dynamic> json) {
    return {{feature_name.pascalCase()}}Model(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unknown',
    );
  }
}
