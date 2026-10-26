class SessionModel {
  const SessionModel({required this.token});

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      SessionModel(token: json['token']?.toString() ?? '');

  final String token;
}
