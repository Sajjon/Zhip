// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

/// Marker-with-payload protocol for views that own a scroll view as part of
/// their composition. Lets generic infrastructure (e.g. pull-to-refresh
/// installation) reach the underlying scroll view without knowing the
/// conforming view's full structure.
public protocol ScrollViewOwner {
    /// The owned scroll view — typically the one that hosts the scene's content.
    var scrollView: UIScrollView { get }
}
