// swift-tools-version: 5.9
//
// Validation — sibling of SingleLineController. The reactive validation
// framework used by SingleLineController-based ViewModels: AnyValidation,
// Validation, EditingValidation, InputValidator, ValidationRule, the
// `eagerValidLazyErrorTurnedToEmptyOnEdit` operator, and the per-field
// validators that consume them.

import PackageDescription

let package = Package(
    name: "Validation",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "Validation", targets: ["Validation"]),
    ],
    dependencies: [
        .package(path: "../SingleLineController"),
    ],
    targets: [
        .target(
            name: "Validation",
            dependencies: [
                .product(name: "SingleLineControllerCore", package: "SingleLineController"),
                .product(name: "SingleLineControllerCombine", package: "SingleLineController"),
            ]
        ),
        .testTarget(
            name: "ValidationTests",
            dependencies: ["Validation"]
        ),
    ]
)
