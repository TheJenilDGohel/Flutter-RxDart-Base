import 'package:rxdart/rxdart.dart';

import '../model/user.dart';

// BLoCs may use RxDart and parse models.
class AuthBloc {
  final _user = BehaviorSubject<User?>.seeded(null);

  Stream<User?> get user => _user.stream;

  void onData(Map<String, dynamic> json) => _user.add(User.fromJson(json));

  void dispose() => _user.close();
}
