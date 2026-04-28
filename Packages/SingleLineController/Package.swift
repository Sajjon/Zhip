// swift-tools-version: 5.9
//
// SingleLineController — reusable reactive-MVVM scaffolding extracted from Zhip.
//
// See https://medium.com/@sajjon/single-line-controller-fbe474857787 and
// https://medium.com/@sajjon/single-line-controller-advanced-case-406e76731ee6
// for the architecture rationale.
//
// Six libraries, layered:
//   Core            — value-types only; no UIKit
//   Combine         — Combine helpers + Binder + --> operator
//   Navigation      — Coordinator pattern + Stepper/Navigator
//   Controller      — UIKit; SceneController, BarButton plumbing, nav-bar layout
//   SceneViews      — UIKit; AbstractSceneView + SingleCellTypeTableView
//   DIPrimitives    — UIKit; protocol-only DI primitives (Clock, MainScheduler,
//                     DateProvider, HapticFeedback, Pasteboard, UrlOpener) with
//                     no dependency on a specific DI container.
//
// Sibling package `Validation/` (in the same monorepo) builds on top of
// SingleLineControllerCore + SingleLineControllerCombine.

import PackageDescription

let package = Package(
    name: "SingleLineController",
    // macOS 13 listed alongside iOS so `swift build`/`swift test` on a
    // macOS host can exercise the Combine APIs. Zhip itself is iOS-only;
    // the macOS minimum exists only for the package's own CLI loop.
    platforms: [.iOS(.v16), .macOS(.v13)],
    products: [
        .library(name: "SingleLineControllerCore", targets: ["SingleLineControllerCore"]),
        .library(name: "SingleLineControllerCombine", targets: ["SingleLineControllerCombine"]),
        .library(name: "SingleLineControllerNavigation", targets: ["SingleLineControllerNavigation"]),
        .library(name: "SingleLineControllerController", targets: ["SingleLineControllerController"]),
        .library(name: "SingleLineControllerSceneViews", targets: ["SingleLineControllerSceneViews"]),
        .library(name: "SingleLineControllerDIPrimitives", targets: ["SingleLineControllerDIPrimitives"]),
    ],
    targets: [
        .target(name: "SingleLineControllerCore"),
        .target(
            name: "SingleLineControllerCombine",
            dependencies: ["SingleLineControllerCore"]
        ),
        .target(
            name: "SingleLineControllerNavigation",
            dependencies: ["SingleLineControllerCore"]
        ),
        .target(
            name: "SingleLineControllerController",
            dependencies: [
                "SingleLineControllerCore",
                "SingleLineControllerCombine",
                "SingleLineControllerNavigation",
                "SingleLineControllerDIPrimitives",
            ]
        ),
        .target(
            name: "SingleLineControllerSceneViews",
            dependencies: [
                "SingleLineControllerCombine",
                "SingleLineControllerController",
            ]
        ),
        .target(name: "SingleLineControllerDIPrimitives"),
        .testTarget(
            name: "SingleLineControllerCoreTests",
            dependencies: ["SingleLineControllerCore"]
        ),
    ]
)
