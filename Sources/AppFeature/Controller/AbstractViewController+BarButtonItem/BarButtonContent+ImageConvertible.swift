// MIT License — Copyright (c) 2018-2026 Open Zesame

import SingleLineControllerController
import UIKit

extension BarButtonContent {
    /// Zhip convenience init that takes an `ImageConvertible` instead of a
    /// raw `UIImage`. Lets call sites pass an asset enum case directly without
    /// resolving to `UIImage` themselves. The package's `init(image:UIImage)`
    /// stays as the primitive entry point.
    init(image: ImageConvertible, style: UIBarButtonItem.Style = .plain) {
        self.init(image: image.image, style: style)
    }
}
