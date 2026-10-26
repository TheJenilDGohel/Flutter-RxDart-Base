class User {
  const User(this.name);

  factory User.fromJson(Map<String, dynamic> json) =>
      User(json['name'] as String);

  static User fromMap(Map<String, dynamic> map) => User(map['name'] as String);

  final String name;
}
