// expect_lint: no_rxdart_in_ui
import 'package:rxdart/rxdart.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

final unusedSubject = BehaviorSubject<int>();

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  void _toggle() {
    // expect_lint: no_setstate_in_widget
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _toggle();
    try {
      throw Exception('Oops');
    } catch (e) {
      // expect_lint: no_exception_tostring
      final text = e.toString();
      return Text(text);
    }
    // Public widget: ScreenUtil is fine here.
    // expect_lint: no_with_opacity
    final _ = const Color(0xFF000000).withOpacity(0.5);
    return SizedBox(width: 10.w, child: const _Badge());
  }
}

class _Badge extends StatelessWidget {
  const _Badge();

  @override
  Widget build(BuildContext context) {
    // expect_lint: no_screenutil_in_private_widget
    return SizedBox(height: 4.h);
  }
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => _CounterState();
}

class _CounterState extends State<_Counter> {
  @override
  Widget build(BuildContext context) {
    // expect_lint: no_screenutil_in_private_widget
    return SizedBox(width: 8.r);
  }
}

// Keeps _Counter referenced.
Widget counter() => const _Counter();
