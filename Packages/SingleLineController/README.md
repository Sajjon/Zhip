# SingleLineController

Reusable reactive-MVVM scaffolding extracted from the
[Zhip](https://github.com/OpenZesame/Zhip) iOS wallet, packaged as a small
suite of layered SPM libraries.

The architecture is described in two articles by the author:

1. [Single Line Controller](https://medium.com/@sajjon/single-line-controller-fbe474857787)
2. [Single Line Controller — advanced cases](https://medium.com/@sajjon/single-line-controller-advanced-case-406e76731ee6)

The core idea: every screen is exactly two files (`<Scene>View.swift` +
`<Scene>ViewModel.swift`), wired together by a generic `SceneController<View>`
that does no business logic of its own. ViewModels expose `transform(input:) -> Output`,
Views expose `inputFromView` + `populate(with:)`, and the `-->` operator binds
publishers into UIKit binders. Zero subclass boilerplate per screen — hence
the "single-line" name (in many cases the coordinator pushes `Scene<MyView>.self`
and that's all the controller code there is).

## Layers

```
SingleLineControllerCore           value-types only; no UIKit
  └─ SingleLineControllerCombine   Combine helpers + Binder + --> operator
       └─ SingleLineControllerNavigation   Coordinator pattern + Navigator
            └─ SingleLineControllerController   SceneController, BarButton plumbing, nav-bar layout
                 └─ SingleLineControllerSceneViews   AbstractSceneView + SingleCellTypeTableView

SingleLineControllerDIPrimitives   protocol-only DI (Clock, MainScheduler, …)
                                    consumed by the layers above; no own deps.
```

Sibling package [`Validation`](../Validation/) (in the same monorepo) builds
on top of `SingleLineControllerCore` + `SingleLineControllerCombine` and ships
the reactive-validation framework (`AnyValidation`, `Validation<Value, Error>`,
`InputValidator`, `ValidationRule`, `eagerValidLazyErrorTurnedToEmptyOnEdit`).

## What's in the package today

| Module                                | Notable types                                                                            |
|---------------------------------------|------------------------------------------------------------------------------------------|
| `SingleLineControllerCore`            | `ViewModelType`, `InputType`, `EmptyInitializable`, `AbstractTarget`, `AbstractViewModel`, `ActivityIndicator`, `ErrorTracker` |
| `SingleLineControllerCombine`         | `Binder<T>`, `-->`, `Publisher+Extras`, `Publisher+Helpers`, `Publisher+Operators`, `UIControl+Publishers`, `UITextField+Publishers`, `UIView+Publishers` |
| `SingleLineControllerNavigation`      | `Navigator<NavigationStep>`, `Navigating`, `Coordinating`, `BaseCoordinator<NavigationStep>`, `CoordinatorTransition`, `Completion`, `DismissScene` |
| `SingleLineControllerController`      | `AbstractController`, `SceneController<View>`, `Scene<View>` typealias, `TitledScene`, `ContentView` typealias, `ViewModelled`, `InputFromController`, `BarButtonContent`, `RightBarButtonContentMaking`/`LeftBarButtonContentMaking`/`BackButtonHiding`, `Toast`, `NavigationBarLayout`/`NavigationBarLayoutOwner`/`NavigationBarLayoutingNavigationController`, all `Coordinating+Scene/Child/Stack/NavigationStack` extensions |
| `SingleLineControllerSceneViews`      | `AbstractSceneView` (open class with `open lazy var refreshControl: UIRefreshControl`), `BaseScrollableStackViewOwner`, `BaseTableViewOwner<Header, Cell>`, `SingleCellTypeTableView<Header, Cell>` (+ `SectionModel`, `CellDeselectionMode`), `TableViewOwner`, `ContentViewProvider`, `ScrollViewOwner`, `PullToRefreshCapable`, `CellConfigurable`, `ClassIdentifiable` + `ReuseIdentifiable`, `SelectionPublishing` + `UITableView.itemSelectedPublisher` |
| `SingleLineControllerDIPrimitives`    | `Clock`/`MainQueueClock`, `MainScheduler`/`DispatchMainScheduler`/`ImmediateMainScheduler`, `DateProvider`/`DefaultDateProvider`, `HapticFeedback`/`DefaultHapticFeedback`, `UrlOpener`/`DefaultUrlOpener`, `Pasteboard`/`DefaultPasteboard` |

## Hard rules

The package depends on `Combine` + `UIKit` + `Foundation` only. NOT Factory,
NOT KeychainSwift, NOT Zesame, NOT any DI container. App-specific hooks
(`InputFromController`'s `Toast` and `BarButtonContent`, `NavigationBarLayout`'s
brand defaults) are exposed as extension-point primitives that consumers
extend in their own modules.

## Status

All six library products are landed and consumed by Zhip:
`SingleLineControllerCore`, `SingleLineControllerCombine`,
`SingleLineControllerNavigation`, `SingleLineControllerController`,
`SingleLineControllerSceneViews`, and `SingleLineControllerDIPrimitives`.

`Toast`, `BarButtonContent`, and `NavigationBarLayout` ship as the small
extension-point primitives the plan called for — Zhip layers its brand
defaults (`.opaque`/`.translucent`/`.hidden` for the layout, `BarButton.skip`
case for the button catalog, `ImageConvertible`-based `BarButtonContent` init)
on top via local extensions. Themed UI (RefreshControl, FooterView,
StackViewStyling, AbstractTableViewCell) stays in Zhip — the package ships
the protocols and chassis classes; consumers ship the brand styling.

Per-package test targets:
- `SingleLineControllerCoreTests` — AbstractTarget, ErrorTracker, smoke tests.
- `SingleLineControllerCombineTests` — Binder, Publisher+Extras, Publisher+Helpers.
- `Validation` package's `ValidationTests` — Validation, AnyValidation, ValidationRule.

App-specific tests (per-domain validators, Zhip coordinator integration tests,
themed-view smoke tests) remain in ZhipTests.
