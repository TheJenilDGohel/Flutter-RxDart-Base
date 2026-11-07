# Recipe fixture

Scaffolding for `tool/smoke.dart`: `tool/harness_recipes.dart` copies these
files into the generated app and replaces each `// recipe-block: N` line and
`recipe('N')` expression with code block N of
`bricks/harness/__brick__/.agents/skills/manage-state/bloc-recipes.md`,
verbatim. `flutter analyze` (which runs the plugin) and
`test/recipes_test.dart` then prove the recipes still compile, follow the
architecture rules and behave as the skill says. Excluded from workspace
analysis (the package is generated).
