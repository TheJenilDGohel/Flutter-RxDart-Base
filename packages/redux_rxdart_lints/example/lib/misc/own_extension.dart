import 'package:flutter/widgets.dart';

// A project's own `.w` extension is not ScreenUtil and must not be flagged.
extension Doubled on num {
  double get w => toDouble() * 2;
}

class _Private extends StatelessWidget {
  const _Private();

  @override
  Widget build(BuildContext context) => SizedBox(width: 3.w);
}

Widget privateWidget() => const _Private();

// A non-Flutter method named setState must not be flagged.
class Machine {
  void setState(int value) {}
  void run() => setState(1);
}
