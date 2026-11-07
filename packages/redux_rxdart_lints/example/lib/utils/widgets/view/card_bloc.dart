import 'package:rxdart/rxdart.dart';

// *_bloc.dart next to a view component is allowed RxDart.
final cardState = BehaviorSubject<bool>.seeded(false);
