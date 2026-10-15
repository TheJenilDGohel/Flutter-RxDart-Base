import { test, expect } from 'claude-code/testing'

const BLOATED_MAESTRO_FAIL = `
Running flow: 09_parent_link_requests.yaml
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
[1/6] Launch App (clearState: true) ... OK
[2/6] Wait for animation ... OK
[3/6] Extended wait until visible: .*Learn your way.* ... OK
[4/6] Tap on: "Skip" ... OK
[5/6] Tap on: point: "60%,26%" ... OK
[6/6] Extended wait until visible: "Check your email" ... FAILED
Error: (line 28: - extendedWaitUntil: visible: "Check your email")
Element not found: Check your email (timeout 15000ms)
View Hierarchy:
  FrameLayout
    LinearLayout
      FlutterView [bounds: 0,0,1080,2400]
        TextView: "Something went wrong"
        TextView: "Server error 500"
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Flow failed: 09_parent_link_requests.yaml
`

const BLOATED_FLUTTER_TEST_FAIL = `
00:01 +0: loading test/features/auth/login_test.dart
00:03 +1 -1: LoginBloc emits success on valid credentials [E]
  Expected: <[ApiResponse.loading(), ApiResponse.completed()]>
    Actual: <[ApiResponse.loading(), ApiResponse.error(ApiError(500))]>
     Which: was <ApiResponse.error(ApiError(500))> at index 1

  package:test_api/src/expect.dart 134:29                expect
  package:matcher/src/expect.dart 150:3                 expect
  test/features/auth/login_test.dart 42:7               main.<fn>
  dart:async/zone.dart 1661:54                          _CustomZone.run
  package:flutter_test/src/binding.dart 1845:14         AutomatedTestWidgetsFlutterBinding.runTest
Some tests failed.
`

test('compacts bloated Maestro failure into concise summary', async ($, on) => {
  on('tool.call', { tool: 'Bash' }, async (_$, e, next) => {
    return {
      result: {
        stdout: BLOATED_MAESTRO_FAIL,
        stderr: '',
      },
    }
  })

  const ran = await $.tool.call({
    tool: 'Bash',
    command: 'maestro test .maestro/flows/09_parent_link_requests.yaml',
  })

  const stdout = (ran.result as any)?.stdout ?? ''
  expect(stdout).toContain('[Maestro Failure Summary]')
  expect(stdout).toContain('Element not found: Check your email')
  expect(stdout).not.toContain('Launch App (clearState: true) ... OK')
})

test('compacts Flutter test failure and filters framework stack trace', async ($, on) => {
  on('tool.call', { tool: 'Bash' }, async (_$, e, next) => {
    return {
      result: {
        stdout: BLOATED_FLUTTER_TEST_FAIL,
        stderr: '',
      },
    }
  })

  const ran = await $.tool.call({
    tool: 'Bash',
    command: 'flutter test test/features/auth/login_test.dart',
  })

  const stdout = (ran.result as any)?.stdout ?? ''
  expect(stdout).toContain('[Flutter Test Failure Summary]')
  expect(stdout).toContain('LoginBloc emits success on valid credentials [E]')
  expect(stdout).toContain('Expected: <[ApiResponse.loading()')
  expect(stdout).toContain('test/features/auth/login_test.dart 42:7')
  expect(stdout).not.toContain('package:test_api/src/expect.dart')
  expect(stdout).not.toContain('dart:async/zone.dart')
})

test('passes unrelated bash commands unchanged', async ($, on) => {
  on('tool.call', { tool: 'Bash' }, async (_$, e, next) => {
    return {
      result: {
        stdout: 'commit abc1234',
        stderr: '',
      },
    }
  })

  const ran = await $.tool.call({
    tool: 'Bash',
    command: 'git status',
  })

  const stdout = (ran.result as any)?.stdout ?? ''
  expect(stdout).toBe('commit abc1234')
})
