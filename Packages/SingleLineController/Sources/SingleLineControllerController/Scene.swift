// MIT License — Copyright (c) 2018-2026 Open Zesame

import SingleLineControllerCore
import UIKit

/// A concrete `UIView` subclass that also conforms to `ViewModelled` — i.e. a view
/// that knows how to construct itself empty (`EmptyInitializable`) and how to bind
/// to its associated ViewModel via `populate(with:)` and `inputFromView`.
///
/// `SceneController<View: ContentView>` is parameterised on this typealias so that
/// the same generic glue can host any `(UIView, ViewModelled)` pair.
public typealias ContentView = UIView & ViewModelled

/// The standard scene-controller "shape" used throughout coordinators.
///
/// Equivalent to `SceneController<View>` plus a static `TitledScene` title. The
/// `where` clause anchors the view-model's controller-side input shape to the
/// package-wide `InputFromController` struct, so coordinators can hand the
/// scene any `View` whose `ViewModel.Input.FromController` matches.
///
/// Use this typealias when you don't require a subclass. If your use case
/// requires a subclass, inherit from `SceneController`.
public typealias Scene<View: ContentView> = SceneController<View> & TitledScene
    where View.ViewModel.Input.FromController == InputFromController
