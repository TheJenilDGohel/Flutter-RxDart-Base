import 'package:rxdart/rxdart.dart';

// Non-widget utils may use RxDart.
Stream<int> merged(Stream<int> a, Stream<int> b) => MergeStream([a, b]);
