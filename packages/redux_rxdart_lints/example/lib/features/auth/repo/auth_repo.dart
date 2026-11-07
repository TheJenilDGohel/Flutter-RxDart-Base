import '../model/user.dart';

class AuthRepo {
  Map<String, dynamic> fetchRaw() => {'name': 'a'};

  User parsed() {
    // expect_lint: repo_transport_only
    return User.fromJson(fetchRaw());
  }

  User parsedFromMap() {
    // expect_lint: repo_transport_only
    return User.fromMap(fetchRaw());
  }

  List<User> tearOff(List<Map<String, dynamic>> rows) {
    // expect_lint: repo_transport_only
    return rows.map(User.fromJson).toList();
  }

  List<User> staticTearOff(List<Map<String, dynamic>> rows) {
    // expect_lint: repo_transport_only
    return rows.map(User.fromMap).toList();
  }
}
