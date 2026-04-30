# Zhip — Testing Guide

This document explains how Zhip's test layer is organized, how dependency
injection works in tests, and what you need to do when adding a new test file
or fresh dependency.

## TL;DR

- **Test framework**: XCTest (Swift Testing can be introduced incrementally —
  the mix is fine).
- **Pattern**: strict Arrange-Act-Assert. One-line arrange / one-line act /
  one-line assert is the goal; more than five lines in any phase is a smell.
- **DI**: every injectable dependency resolves from `Container.shared`
  (`Sources/AppFeature/DI/Container.swift`). Tests substitute fakes with
  `Container.shared.<factory>.register { Mock() }` and `Container.shared.reset()`
  in `tearDown`.
- **Running locally**: `just test` (unit tests) or `just cov` (tests + coverage
  table). `just cov-detailed` highlights every uncovered line — read it when
  triaging low coverage areas.

---

## Directory layout

```
Tests/
├── Configurations/            # xcconfig files
├── Extensions/
│   └── ViewModel/             # helpers that extend ZHIP types for tests
├── Helpers/                   # ← new in this refactor. See "Helpers" below.
│   ├── InMemoryKeyValueStore.swift
│   ├── TestStoreFactory.swift
│   ├── InputFromControllerFactory.swift
│   └── MockOnboardingUseCase.swift
├── SupportingFiles/           # Info.plist
└── Tests/
    ├── AutoEnumCaseNameTests.swift
    ├── BalanceLastUpdatedFormatterTests.swift
    ├── CharacterSetTests.swift
    ├── StringFormattingTests.swift
    ├── DI/
    │   └── ContainerTests.swift
    ├── UseCases/
    │   ├── DefaultOnboardingUseCaseTests.swift
    │   └── DefaultPincodeUseCaseTests.swift
    └── ViewModels/
        ├── AskForCrashReportingPermissionsViewModelTests.swift
        ├── TermsOfServiceViewModelTests.swift
        └── WelcomeViewModelTests.swift
```

---

## First-time setup: adding new files to the Xcode project

**The `Tests/` directory on disk is not automatically synced to the
`ZhipTests` target.** When you pull these refactor commits, Xcode won't see
the new files in `Tests/Helpers/` or `Tests/Tests/**/` until you add them to
the target. One-time setup:

1. Open `Zhip.xcodeproj` in Xcode.
2. Right-click the `ZhipTests` group → **Add Files to "Zhip"…**.
3. Select the `Tests/Helpers/` and `Tests/Tests/DI/`, `Tests/Tests/UseCases/`,
   `Tests/Tests/ViewModels/` directories.
4. In the dialog: uncheck "Copy items if needed", set Targets → only
   **ZhipTests**, click Add.
5. Same story for `Sources/AppFeature/DI/Container.swift` — add to the **Zhip**
   target (not ZhipTests).

You can confirm everything is wired by running `just test`.

---

## Writing a use-case test

Use cases with no external SDK dependencies (pincode, onboarding) are easiest:

```swift
final class DefaultPincodeUseCaseTests: XCTestCase {

    private var preferences: Preferences!
    private var secureStore: SecurePersistence!
    private var sut: DefaultPincodeUseCase!

    override func setUp() {
        super.setUp()
        preferences = TestStoreFactory.makePreferences()
        secureStore = TestStoreFactory.makeSecurePersistence()
        sut = DefaultPincodeUseCase(preferences: preferences, securePersistence: secureStore)
    }

    override func tearDown() {
        sut = nil
        secureStore = nil
        preferences = nil
        super.tearDown()
    }

    func test_hasConfiguredPincode_isTrue_afterUserChoosesPincode() throws {
        // Arrange
        let pin = try Pincode(digits: [.one, .two, .three, .four])
        // Act
        sut.userChoose(pincode: pin)
        // Assert
        XCTAssertTrue(sut.hasConfiguredPincode)
    }
}
```

The helpers (`TestStoreFactory`, `FakeInputFromController`, `MockOnboardingUseCase`)
all live under `Tests/Helpers/` and use `@testable import Zhip`.

### Known quirks to be aware of

- `KeyValueStore<KeychainKey>.wallet` reads from `Preferences.default`
  (`UserDefaults.standard`) to detect a first launch.
  `TestStoreFactory.makeSecurePersistence()` preemptively flips
  `hasRunAppBefore` to `true` in UserDefaults so the getter doesn't wipe out
  the in-memory test state. This is a global side-effect — if your test needs
  to assert on the "first launch" branch, register a different `preferences`
  via `Container.shared.preferences.register { ... }`.
- `DefaultOnboardingUseCase.answeredCrashReportingQuestion(...)` calls into
  Firebase (`setupCrashReportingIfAllowed`). We deliberately don't exercise
  that side-effect in a unit test because Firebase would need to be configured
  at runtime. Re-architect `DefaultOnboardingUseCase` to inject a
  `CrashReportingConfigurator` dependency if you want full coverage.

---

## Writing a view-model test

ViewModels are tested by driving their `InputFromView` subjects and observing
`navigator.navigation` + `output` publishers:

```swift
func test_didAcceptTerms_callsUseCaseAndEmitsAccept() {
    // Arrange
    let useCase = MockOnboardingUseCase()
    let didAcceptTerms = PassthroughSubject<Void, Never>()
    let sut = TermsOfServiceViewModel(useCase: useCase, isDismissible: false)
    let input = TermsOfServiceViewModel.Input(
        fromView: .init(
            didScrollToBottom: Empty().eraseToAnyPublisher(),
            didAcceptTerms: didAcceptTerms.eraseToAnyPublisher()
        ),
        fromController: FakeInputFromController().makeInput()
    )
    _ = sut.transform(input: input)
    var observed: TermsOfServiceNavigation?
    sut.navigator.navigation.sink { observed = $0 }.store(in: &cancellables)

    // Act
    didAcceptTerms.send(())

    // Assert
    XCTAssertEqual(useCase.didAcceptTermsOfServiceCallCount, 1)
}
```

`FakeInputFromController` exposes every subject the real `InputFromController`
sees. Feed it with the lifecycle events your test needs; inspect the output
subjects (`titleSubject`, `toastSubject`, etc.) to assert that the ViewModel
reacted correctly.

---

## Dependency-injection container (`Container`)

The DI layer lives at `Sources/AppFeature/DI/Container.swift`. It is
intentionally shaped like [hmlongco/Factory](https://github.com/hmlongco/Factory)
so you can swap this in-repo implementation for the real SPM package with
~zero call-site churn:

```swift
// Production
let wallet = Container.shared.walletUseCase()

// Test-time override
Container.shared.walletUseCase.register { MyMockWalletUseCase() }
// ...test code...
Container.shared.reset()  // tearDown
```

### Registered dependencies

| Factory | Type | Default |
|---------|------|---------|
| `zilliqaService` | `ZilliqaServiceReactive` | `DefaultZilliqaService(network: .mainnet).combine` |
| `preferences` | `Preferences` | `KeyValueStore(UserDefaults.standard)` |
| `securePersistence` | `SecurePersistence` | `KeyValueStore(KeychainSwift())` |
| `walletUseCase` | `WalletUseCase` | `DefaultWalletUseCase` wired to the services above |
| `transactionsUseCase` | `TransactionsUseCase` | `DefaultTransactionsUseCase` |
| `onboardingUseCase` | `OnboardingUseCase` | `DefaultOnboardingUseCase` |
| `pincodeUseCase` | `PincodeUseCase` | `DefaultPincodeUseCase` |
| `useCaseProvider` | `UseCaseProvider` | `DefaultUseCaseProvider` |
| `createWalletUseCase` / `restoreWalletUseCase` / `walletStorageUseCase` / `verifyEncryptionPasswordUseCase` / `extractKeyPairUseCase` | narrow facets | point at `walletUseCase()` |
| `balanceCacheUseCase` / `gasPriceUseCase` / `fetchBalanceUseCase` / `sendTransactionUseCase` / `transactionReceiptUseCase` | narrow facets | point at `transactionsUseCase()` |

### Migrating to real Factory

When you want to swap in the real SPM package:

1. Add `https://github.com/hmlongco/Factory` as a Swift Package dependency of
   the Zhip target.
2. Delete `Sources/AppFeature/DI/Container.swift`.
3. Replace the file with a set of `Container` extensions that use Factory's
   `@Injected` / `Factory` property wrappers. The registered types are
   unchanged, so call sites (`Container.shared.walletUseCase()`) continue to
   compile.

---

## Snapshot testing

Snapshot testing is **not yet wired in**. To enable it:

1. Add `https://github.com/pointfreeco/swift-snapshot-testing` as an SPM
   dependency of the `ZhipTests` target (Xcode → File → Add Package
   Dependencies…).
2. Create `Tests/Tests/Snapshots/` and put one `*ViewTests.swift` per scene
   view, using the `SnapshotTesting` API:

   ```swift
   import SnapshotTesting
   import XCTest
   @testable import Zhip

   final class WelcomeViewTests: XCTestCase {
       func test_welcomeView_rendersCorrectly() {
           // Arrange
           let view = WelcomeView()
           view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
           view.populate(with: .init()) // or mocked output
           // Act + Assert
           assertSnapshot(of: view, as: .image(precision: 0.99))
       }
   }
   ```

3. Run the test once to record snapshots (`record = true`), then commit the
   generated `__Snapshots__/` directory.

Once set up, snapshot tests should cover every top-level view in
`Sources/AppFeature/Scenes/`: Welcome, TermsOfService, AskForCrashReportingPermissions,
WarningCustomECC, ChooseWallet, Main, Send, Receive, Settings, and the
pincode / backup flows.

---

## Coverage targets

Run `just cov` for a per-file table, `just cov-detailed` to see individual
uncovered lines. Current aspiration:

- **Use cases**: 95%+ (pincode + onboarding already testable; wallet +
  transactions need a `ZilliqaServiceReactive` fake — see below).
- **ViewModels**: 90%+ by mocking their use cases.
- **Views**: validated via snapshot tests for rendering + interaction via
  ViewModel tests.
- **Validators / formatters / extensions**: 100% — they're pure functions.

### Faking `ZilliqaServiceReactive`

`Zesame.ZilliqaServiceReactive` is an external protocol with many methods.
To unit-test `DefaultWalletUseCase` / `DefaultTransactionsUseCase` without
touching the network, you need a hand-rolled `FakeZilliqaService` that
conforms to the protocol and stubs every method — probably 20-30 lines per
method. This is the biggest remaining blocker to 95% coverage on the use
case layer. If you build one, put it in
`Tests/Helpers/FakeZilliqaService.swift` and register it with
`Container.shared.zilliqaService.register { FakeZilliqaService() }`.

---

## Reference: test naming convention

- Use backticks + plain English for Swift Testing (`@Test`):
  `@Test("ensure a new wallet creates a random private key")`.
- Use `test_<subject>_<expectation>` for XCTest:
  `test_didAcceptTerms_callsUseCaseAndEmitsAccept`.
- Names that read like "subject verb expectation" beat Hungarian-style
  `testDidAcceptTerms1` every time.
