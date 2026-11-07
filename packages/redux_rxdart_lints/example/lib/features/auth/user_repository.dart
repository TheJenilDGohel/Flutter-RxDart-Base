import 'model/user.dart';

// Named *_repository.dart outside a repo/ folder: still a repository.
class UserRepository {
  // expect_lint: repo_transport_only
  User parse(Map<String, dynamic> json) => User.fromJson(json);
}
