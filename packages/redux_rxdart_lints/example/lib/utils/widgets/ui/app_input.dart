import 'package:flutter/widgets.dart';

// Design-system primitives in utils/widgets/ui/ may hold visual state.
class AppInput extends StatefulWidget {
  const AppInput({super.key});

  @override
  State<AppInput> createState() => AppInputState();
}

class AppInputState extends State<AppInput> {
  bool obscured = true;

  void toggle() => setState(() => obscured = !obscured);

  @override
  Widget build(BuildContext context) => const SizedBox();
}
