import 'package:rxdart/rxdart.dart';

// Recipe D, BLoC side.
// recipe-block: 7a

final class CartBloc {
  // recipe-block: 7b

  void add() => _notify(CartEvent.added);

  void dispose() => _events.close();
}
