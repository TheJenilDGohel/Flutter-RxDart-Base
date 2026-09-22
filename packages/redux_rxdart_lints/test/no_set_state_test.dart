import 'package:flutter/widgets.dart';

class MyWidget extends StatefulWidget {
  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  void _doSomething() {
    // expect_lint: no_setstate_in_widget
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
