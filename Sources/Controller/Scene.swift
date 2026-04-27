//
// MIT License
//
// Copyright (c) 2018-2026 Open Zesame (https://github.com/OpenZesame)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.
//

import SingleLineControllerCore
import UIKit

/// A concrete `UIView` subclass that also conforms to `ViewModelled` — i.e. a view
/// that knows how to construct itself empty (`EmptyInitializable`) and how to bind
/// to its associated ViewModel via `populate(with:)` and `inputFromView`.
///
/// `SceneController<View: ContentView>` is parameterised on this typealias so that
/// the same generic glue can host any `(UIView, ViewModelled)` pair.
typealias ContentView = UIView & ViewModelled

/// The standard scene-controller "shape" used throughout coordinators.
///
/// Equivalent to `SceneController<View>` plus a static `TitledScene` title. The
/// `where` clause anchors the view-model's controller-side input shape to the
/// project-wide `InputFromController` struct, so coordinators can hand the
/// scene any `View` whose `ViewModel.Input.FromController` matches.
///
/// Use this typealias when you don't require a subclass. If your use case
/// requires subclass, inherit from `SceneController`.
typealias Scene<View: ContentView> = SceneController<View> & TitledScene
    where View.ViewModel.Input.FromController == InputFromController
