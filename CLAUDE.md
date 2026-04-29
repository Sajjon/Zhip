# Zhip — Codebase Guide for Claude

## Overview

Zhip is an iOS Zilliqa wallet app built with UIKit + Combine using a custom MVVM architecture centered on reactive data-binding. The app targets **iOS 16.6**.

The reactive layer is Apple's `Combine` framework throughout. There are no RxSwift/RxCocoa/RxDataSources dependencies — all streams are `AnyPublisher`, all subjects are `PassthroughSubject`/`CurrentValueSubject`, and subscription lifetime is managed by `Set<AnyCancellable>`.

The reactive-MVVM scaffolding (`ViewModelType`, `Binder<T>`, `-->`, `Coordinating`/`BaseCoordinator`/`Navigator`, the DI primitives, the validation framework) lives in a single flat SPM package at the repo root (`/Package.swift`), with one library product per module:

- `SingleLineControllerCore` / `Combine` / `Navigation` / `Controller` / `SceneViews` / `DIPrimitives` — the SLC architecture itself.
- `Validation` — sibling reactive-validation framework consumed by the SLC layer.
- `Resources` — bundled fonts/html/audio (Bundle.module shim).

Sources for each SPM target live at `/Sources/<TargetName>/`. The Zhip-app source code (Application/, Scenes/, Views/, etc.) currently lives at `/Sources/Application/` etc. — consumed by the Zhip iOS-app target directly until it migrates into per-feature SPM modules.

### Project generation

The `Zhip.xcodeproj` is **generated** from `/project.yml` via XcodeGen and is gitignored. After cloning / checking out / changing `project.yml`:

```sh
just gen   # alias for `xcodegen generate`
```

`just test` / `just cov` etc. assume `Zhip.xcodeproj` exists, so run `just gen` first.

---

## Architecture: Reactive MVVM with `SceneController<View>`

### Core Concept

Every screen consists of exactly two files:
- **`<Scene>View.swift`** — UIView subclass conforming to `ViewModelled`
- **`<Scene>ViewModel.swift`** — inherits `BaseViewModel`, implements `ViewModelType`

A generic `SceneController<View>` instantiates both, wires them together, and is almost never subclassed. The "scene controller" is the glue, not the business logic.

### Data Flow (Unidirectional)

```
User Action (tap, type, toggle)
        ↓
InputFromView struct  ←  View's `inputFromView` computed property
        ↓
ViewModel.Input(fromView:, fromController:)
        ↓
ViewModel.transform(input:) → Output
        ↓
View.populate(with: output) → [AnyCancellable]
        ↓
UI updated via `-->` operator binding outputs to Binders
```

---

## Key Protocols & Types

### `ViewModelType`
**File**: `Sources/Application/ViewModel/ViewModelType.swift`

```swift
protocol ViewModelType {
    associatedtype Input: InputType
    associatedtype OutputVM
    func transform(input: Input) -> OutputVM
}
```

All ViewModels implement `transform`. It is the only public method — input in, output out.

### `InputType`
**File**: `Sources/Application/ViewModel/InputType.swift`

```swift
protocol InputType {
    associatedtype FromView
    associatedtype FromController
    var fromView: FromView { get }
    var fromController: FromController { get }
    init(fromView: FromView, fromController: FromController)
}
```

Every ViewModel's `Input` has two channels:
- `fromView` — user interactions (taps, text, toggles) as `AnyPublisher<T, Never>`
- `fromController` — lifecycle events and navigation subjects from `InputFromController`

### `ViewModelled`
**File**: `Sources/Views/Protocols/ViewModelled.swift`

```swift
protocol ViewModelled: EmptyInitializable {
    associatedtype ViewModel: ViewModelType
    typealias InputFromView = ViewModel.Input.FromView
    var inputFromView: InputFromView { get }
    func populate(with viewModel: ViewModel.OutputVM) -> [AnyCancellable]
}
```

Views provide:
- `inputFromView` — computed property building the `InputFromView` struct from UIKit publisher extensions
- `populate(with:)` — binds ViewModel output streams back to UI controls, returns `[AnyCancellable]`

### `InputFromController`
**File**: `Sources/Application/ViewModel/InputFromController.swift`

```swift
struct InputFromController {
    let viewDidLoad: AnyPublisher<Void, Never>
    let viewWillAppear: AnyPublisher<Void, Never>
    let viewDidAppear: AnyPublisher<Void, Never>
    let leftBarButtonTrigger: AnyPublisher<Void, Never>
    let rightBarButtonTrigger: AnyPublisher<Void, Never>
    let titleSubject: PassthroughSubject<String, Never>         // ViewModel sends → controller updates nav title
    let leftBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>
    let rightBarButtonContentSubject: PassthroughSubject<BarButtonContent, Never>
    let toastSubject: PassthroughSubject<Toast, Never>
}
```

The subjects are passed *into* the ViewModel so it can imperatively push navigation/title/toast updates via `.send(...)`.

### `AbstractViewModel` / `BaseViewModel`

```
AbstractViewModel<FromView, FromController, Output>  (has cancellables: Set<AnyCancellable>, defines Input struct)
    └── BaseViewModel<NavigationStep, FromView, Output>  (adds navigator: Navigator<Step>)
            └── Concrete ViewModels
```

`BaseViewModel` conforms to `Navigating` which lets the ViewModel emit navigation steps picked up by the coordinator.

---

## SceneController — The Orchestrator
**File**: `Sources/Controller/SceneController.swift`

```swift
class SceneController<View: ContentView>: AbstractController
    where View.ViewModel.Input.FromController == InputFromController
```

Key responsibility chain on init:
1. Creates `View()` (via `EmptyInitializable`)
2. `makeAndSubscribeToInputFromController()` — builds `InputFromController` with lifecycle publishers and subscribed subjects
3. `viewModel.transform(input:)` — runs the ViewModel transformation
4. `rootContentView.populate(with: output)` — establishes all UI bindings; each cancellable stored in `cancellables: Set<AnyCancellable>`

`SceneController` is never overridden for logic — it's purely mechanical wiring.

### `TitledScene`
**File**: `Sources/Controller/TitledScene.swift`

Optional protocol on `SceneController` subclasses. When conformed, `SceneController` sets `title` automatically from `static var title: String`.

### Scene Typealias
**File**: `Sources/Controller/Scene.swift`

```swift
typealias Scene<View: ContentView> = SceneController<View> & TitledScene
    where View.ViewModel.Input.FromController == InputFromController
```

Used throughout coordinators: `Scene<ChoosePincodeView>`, `Scene<SettingsView>`, etc.

---

## The `-->` Binding Operator
**File**: `Sources/Extensions/Combine/Publisher+Operators.swift`

```swift
infix operator -->
func --> <T>(publisher: AnyPublisher<T, Never>, binder: Binder<T>) -> AnyCancellable {
    publisher.receive(on: RunLoop.main).sink { binder.on($0) }
}
```

Overloaded for `Binder<T?>`, `UILabel`, `UITextView` (so publishers of `String`/`String?` can bind directly to labels and text views).

Subscription management uses Combine's native `.store(in: &cancellables)` — there is no custom `<~` operator.

Usage in `populate`:
```swift
func populate(with viewModel: ViewModel.Output) -> [AnyCancellable] {
    [
        viewModel.isContinueButtonEnabled --> continueButton.isEnabledBinder,
        viewModel.encryptionPasswordValidation --> encryptionPasswordField.validationBinder,
    ]
}
```

Usage in ViewModel `transform`:
```swift
[
    input.fromView.createWalletTrigger
        .handleEvents(receiveOutput: { userIntends(to: .createWallet) })
        .sink { _ in },
].forEach { $0.store(in: &cancellables) }
```

---

## Custom UIKit Publisher Extensions

Generic publisher/binder extensions live in `Sources/Extensions/UIKit/UIViews+Publishers/`; view-specific ones live in the view file itself.

| Extension | File | Type |
|-----------|------|-----|
| `UITextField.placeholderBinder` | `UITextField+Publishers.swift` | `Binder<String?>` |
| `UITextField.textBinder` | `UITextField+Publishers.swift` | `Binder<String?>` |
| `UITextField.isEditingPublisher` | `UITextField+Publishers.swift` | `AnyPublisher<Bool, Never>` |
| `UITextField.didEndEditingPublisher` | `UITextField+Publishers.swift` | `AnyPublisher<Void, Never>` |
| `UIView.isVisibleBinder` | `UIView+Publishers.swift` | `Binder<Bool>` |
| `UIView.imageBinder` | `UIView+Publishers.swift` | `Binder<UIImage?>` |
| `UIControl.becomeFirstResponderBinder` | `UIControl+Publishers.swift` | `Binder<Void>` |
| `UIControl.isEnabledBinder` | `UIControl+Publishers.swift` | `Binder<Bool>` |
| `UIControl.tapPublisher` / `publisher(for:)` | `UIControl+Publisher.swift` | `AnyPublisher<Void/UIControl.Event, Never>` |
| `FloatingLabelTextField.validationBinder` | `FloatingLabelTextField.swift` | `Binder<AnyValidation>` |
| `CheckboxView.isCheckedPublisher` | `CheckboxWithLabel.swift` | `AnyPublisher<Bool, Never>` |
| `ButtonWithSpinner.isLoadingBinder` | `ButtonWithSpinner.swift` | `Binder<Bool>` |
| `SpinnerView.isLoadingBinder` | `SpinnerView.swift` | `Binder<Bool>` |
| `AbstractSceneView.isRefreshingBinder` | `AbstractSceneView.swift` | `Binder<Bool>` |
| `AbstractSceneView.pullToRefreshTitleBinder` | `AbstractSceneView.swift` | `Binder<String>` |
| `AbstractSceneView.pullToRefreshTriggerPublisher` | `AbstractSceneView.swift` | `AnyPublisher<Void, Never>` |
| `UITableView.footerLabelBinder` | `UITableView+Footer.swift` | `Binder<String>` |

---

## Table Views

`SingleCellTypeTableView<Header, Cell>` in `Sources/Views/TableView/SingleCellTypeTableView.swift` is backed by `UITableViewDiffableDataSource`. Sections arrive as `AnyPublisher<[SectionSnapshot<Header, Cell.Model>], Never>` and item selection is exposed as `didSelectItem: AnyPublisher<IndexPath, Never>`.

Used by `SettingsView` and similar table-backed screens.

---

## Validation System

`AnyValidation` enum with `.valid(withRemark:)`, `.empty`, `.errorMessage(String)`.
`FloatingLabelTextField.validationBinder` takes an `AnyValidation` and applies visual feedback.
ViewModels produce `AnyPublisher<AnyValidation, Never>` and bind it with `-->`.

## Activity Tracking

`ActivityIndicator` (wraps `CurrentValueSubject<Bool, Never>`) tracks async operations:
```swift
someAsyncPublisher.trackActivity(activityIndicator)
// activityIndicator.asPublisher() → AnyPublisher<Bool, Never> → button.isLoadingBinder
```

---

## Navigation / Coordination

`BaseViewModel` holds `navigator: Navigator<NavigationStep>` (a `Stepper`).
Coordinators subscribe to the navigator's `navigation: AnyPublisher<NavigationStep, Never>` and handle screen transitions.
ViewModels call `userIntends(to: .someStep)` to trigger navigation.

Coordinators hold a `cancellables: Set<AnyCancellable>` for retaining navigation subscriptions.

---

## Use Cases

Use cases live in `Sources/UseCases/`. The wallet subsystem is split into five
narrow protocols, each backed by its own concrete `Default*` implementation
that uses `@Injected` to resolve its own dependencies. The transactions,
onboarding, and pincode subsystems still have a composite façade protocol
(kept for now — prefer the narrow protocols in new code) plus per-facet
factories that all resolve to the same shared instance.

### Wallet subsystem (fully split)

| Narrow protocol | Concrete implementation | What it injects |
|-----------------|------------------------|-----------------|
| `CreateWalletUseCase` | `DefaultCreateWalletUseCase` | `zilliqaService` |
| `RestoreWalletUseCase` | `DefaultRestoreWalletUseCase` | `zilliqaService` |
| `WalletStorageUseCase` | `DefaultWalletStorageUseCase` | `securePersistence` |
| `VerifyEncryptionPasswordUseCase` | `DefaultVerifyEncryptionPasswordUseCase` | `zilliqaService` |
| `ExtractKeyPairUseCase` | `DefaultExtractKeyPairUseCase` | `zilliqaService` |

Each ViewModel/coordinator depends on *only* the narrow protocols it
actually uses (`@Injected(\.createWalletUseCase) private var createWalletUseCase: CreateWalletUseCase`).

### Other subsystems (composite + narrow facets)

| Composite | Narrow protocols |
|-----------|------------------|
| `TransactionsUseCase` | `BalanceCacheUseCase`, `GasPriceUseCase`, `FetchBalanceUseCase`, `SendTransactionUseCase`, `TransactionReceiptUseCase` |
| `OnboardingUseCase` | `TermsOfServiceAcceptanceUseCase`, `CustomECCWarningAcceptanceUseCase`, `CrashReportingPermissionsUseCase`, `PincodePromptUseCase` |
| `PincodeUseCase` | `PincodeReadUseCase`, `PincodeWriteUseCase` |

The single `Default{Transactions,Onboarding,Pincode}UseCase` concrete type
conforms to every narrow protocol in its family, so the per-facet factories
all resolve to the same shared instance (no adapter glue needed).

---

## Dependency Injection: `Container`

The shared DI container is `Container.shared`, implemented in
`Sources/Application/DI/Container.swift`. Its API mirrors
[hmlongco/Factory](https://github.com/hmlongco/Factory) so a future swap to
the real SPM package is a near-no-op.

```swift
// Production
let storage = Container.shared.walletStorageUseCase()

// Test
Container.shared.walletStorageUseCase.register { MockWalletUseCase() }
// ...
Container.shared.manager.reset()  // restores every registered default
```

Each factory follows the pattern `lazy var <name>: Factory<Protocol> = _register { ... }`.
See `Container.swift` for the full list (services, composite use cases, and
narrow use case facets that all resolve to the same shared instance).

See **TESTING.md** for concrete test patterns and how to add new
`Tests/Helpers/*` files to the `ZhipTests` target.

---

## Testing

- Framework: XCTest (`just test` / `just cov` / `just cov-detailed`).
- Pattern: strict Arrange-Act-Assert with one-line sections where possible.
- ViewModel tests drive `InputFromView` subjects via `FakeInputFromController`
  and observe `navigator.navigation`.
- Use-case tests use `TestStoreFactory.makePreferences()` /
  `TestStoreFactory.makeSecurePersistence()` for in-memory stores.
- Snapshot testing (`swift-snapshot-testing`) is scaffolded in TESTING.md but
  not yet added as an SPM dep on `ZhipTests`.

Full guide: [TESTING.md](./TESTING.md).

---

## Key File Locations

| Concept | Path |
|---------|------|
| `ViewModelType` | `Sources/Application/ViewModel/ViewModelType.swift` |
| `InputType` | `Sources/Application/ViewModel/InputType.swift` |
| `ViewModelled` | `Sources/Views/Protocols/ViewModelled.swift` |
| `AbstractViewModel` | `Sources/Application/ViewModel/BaseClasses/AbstractViewModel.swift` |
| `BaseViewModel` | `Sources/Application/ViewModel/BaseClasses/BaseViewModel.swift` |
| `SceneController` | `Sources/Controller/SceneController.swift` |
| `InputFromController` | `Sources/Application/ViewModel/InputFromController.swift` |
| `Scene` typealias | `Sources/Controller/Scene.swift` |
| `Binder` + `-->` operator | `Sources/Extensions/Combine/Binder.swift`, `Publisher+Operators.swift` |
| Publisher helpers (`mapToVoid`, `filterNil`, `orEmpty`, `withLatestFrom`, etc.) | `Sources/Extensions/Combine/Publisher+Extras.swift`, `Publisher+Helpers.swift` |
| `ActivityIndicator` | `Sources/Application/ViewModel/ActivityIndicator.swift` |
| `AnyValidation` | `Sources/Application/InputValidators/Validation/AnyValidation/AnyValidation.swift` |
| `SingleCellTypeTableView` | `Sources/Views/TableView/SingleCellTypeTableView.swift` |
| `Factory` + `Container` | `Sources/Application/DI/Container.swift` |
| Use case protocols | `Sources/UseCases/*.swift` |
| `Default*UseCase` | `Sources/UseCases/Implementations/*.swift` |
