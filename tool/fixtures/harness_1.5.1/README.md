# Harness 1.5.1 contracts

`CLAUDE.md` and `AGENTS.md` exactly as harness 1.5.1 rendered them for
`legacy_app` (`com.acme.legacy` / `com.acme.legacy-ios`). Pre-1.6 files have
no project-rules marker, so `tool/test_harness_upgrade.dart` adds team edits
to them and checks that the upgrade keeps those edits and drops only
template lines.
