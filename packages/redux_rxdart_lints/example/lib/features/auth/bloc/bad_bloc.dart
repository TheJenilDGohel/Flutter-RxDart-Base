import 'package:rxdart/rxdart.dart';

class BadBloc {
  // expect_lint: no_unclosed_subject
  final unclosed = BehaviorSubject<int>();

  // expect_lint: no_fetch_without_token
  Future<void> fetch() async {
    // does not call createNewToken()
  }

  void dispose() {
    // unclosed is not closed!
  }
}
