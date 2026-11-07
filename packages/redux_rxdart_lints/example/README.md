# redux_rxdart_lints fixture

Each file under `lib/` exercises one rule. Lines that must be flagged carry
`// expect_lint: <rule>` on the line above; everything else must stay clean.
`tool/check_fixture.dart` fails on a missing expected diagnostic *and* on an
unexpected one. Run it from the package root (one level up):

```bash
dart run tool/check_fixture.dart
```
