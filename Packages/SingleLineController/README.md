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
            └─ SingleLineControllerController   AbstractController (more landing here)
                 └─ SingleLineControllerSceneViews   AbstractSceneView (placeholder)

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
| `SingleLineControllerController`      | `AbstractController` (more landing in a follow-up: `SceneController`, `Scene`, `TitledScene`, `InputFromController`, `BarButton`, `Toast`, `NavigationBarLayout`) |
| `SingleLineControllerSceneViews`      | _placeholder — landing in a follow-up_                                                   |
| `SingleLineControllerDIPrimitives`    | `Clock`/`MainQueueClock`, `MainScheduler`/`DispatchMainScheduler`/`ImmediateMainScheduler`, `DateProvider`/`DefaultDateProvider`, `HapticFeedback`/`DefaultHapticFeedback`, `UrlOpener`/`DefaultUrlOpener`, `Pasteboard`/`DefaultPasteboard` |

## Hard rules

The package depends on `Combine` + `UIKit` + `Foundation` only. NOT Factory,
NOT KeychainSwift, NOT Zesame, NOT any DI container. App-specific hooks
(`InputFromController`'s `Toast` and `BarButtonContent`, `NavigationBarLayout`'s
brand defaults) are exposed as extension-point primitives that consumers
extend in their own modules.

## Status

This package was extracted from Zhip in stages. As of this writing, the
core/combine/navigation/DIPrimitives layers are fully landed; the
controller layer has only `AbstractController` so far. The remaining
`SceneController` + supporting types are tracked under "Phase 5b" in the
extraction plan and will be landed in a follow-up that introduces the
extension-point hooks for `Toast` / `BarButtonContent` / `NavigationBarLayout`.
