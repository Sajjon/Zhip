// MIT License — Copyright (c) 2018-2026 Open Zesame

import UIKit

public extension UIView {
    /// Binder driving the *negated* `isHidden` state — i.e. `true` shows,
    /// `false` hides.
    var isVisibleBinder: Binder<Bool> {
        Binder(self) { view, isVisible in
            view.isHidden = !isVisible
        }
    }
}

public extension UIImageView {
    /// Binder driving the image view's `image`.
    var imageBinder: Binder<UIImage?> {
        Binder(self) { imageView, image in
            imageView.image = image
        }
    }
}
