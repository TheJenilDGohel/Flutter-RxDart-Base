// no_fetch_without_token follows calls from fetch() into the BLoC's own
// methods (a few levels deep), including keyed tokens.

class _Token {}

/// One token per key, as in the project brick's `KeyedCancelTokens`.
class _KeyedTokens<K> {
  final Map<K, _Token> _tokens = {};

  _Token createNewToken(K key) => _tokens[key] = _Token();
}

class DelegatingBloc {
  _Token? _token;

  _Token createNewToken() => _token = _Token();

  // Clean: fetch -> _load -> _run -> createNewToken().
  Future<void> fetch() => _load();

  Future<void> _load() async => _run();

  void _run() {
    createNewToken();
  }

  _Token? get token => _token;
}

class KeyedTabsBloc {
  final _tokens = _KeyedTokens<int>();

  // Clean: one token per tab, renewed in the private loader.
  Future<void> fetch({bool refresh = false}) => _load(0, refresh);

  Future<void> _load(int tab, bool refresh) async {
    _tokens.createNewToken(tab);
  }
}

class DeadEndBloc {
  // expect_lint: no_fetch_without_token
  Future<void> fetch() => _load();

  Future<void> _load() async {}
}

class CycleBloc {
  // expect_lint: no_fetch_without_token
  Future<void> fetch() async => _a();

  void _a() => _b();

  void _b() => _a();
}
