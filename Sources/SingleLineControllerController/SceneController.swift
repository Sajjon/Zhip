// MIT License — Copyright (c) 2018-2026 Open Zesame

import Combine
import SingleLineControllerCore
import SingleLineControllerDIPrimitives
import UIKit

/// The "Single-Line Controller" base class.
///
/// `SceneController<View>` is the generic scene glue: given a `ViewModelled` view
/// type and its associated ViewModel, it instantiates the view, builds an
/// `InputFromController`, invokes `viewModel.transform(input:)`, and binds the
/// output back to the view via `View.populate(with:)`. It is almost never
/// subclassed — coordinators push instances of this class directly using the
/// `Scene` typealias.
open class SceneController<View: ContentView>: AbstractController
    where View.ViewModel.Input.FromController == InputFromController
// swiftlint:disable:next opening_brace
{
    /// Convenience alias for the view's ViewModel type.
    public typealias ViewModel = View.ViewModel

    /// Bag of Combine subscriptions owned by this controller (navigation bar bindings,
    /// toasts, title updates, view ↔ view-model bindings).
    private var cancellables = Set<AnyCancellable>()

    /// The ViewModel injected by the coordinator at construction time.
    public let viewModel: ViewModel

    /// Clock used to auto-dismiss toasts emitted via `InputFromController.toastSubject`.
    /// Defaults to a real `MainQueueClock`. Subclasses (or test fakes) override
    /// to substitute an immediate clock so toast auto-dismiss skips the runloop.
    open var clock: any Clock { MainQueueClock() }

    /// Optional override-point: the colour the controller's `view.backgroundColor`
    /// is set to in `viewDidLoad`. Defaults to `.systemBackground`. Subclasses
    /// (or app-level extensions) override this to apply a brand background.
    open var rootBackgroundColor: UIColor { .systemBackground }

    /// Fires when `viewDidLoad` runs. Piped into `InputFromController.viewDidLoad`.
    private let viewDidLoadSubject = PassthroughSubject<Void, Never>()

    /// Fires each time `viewWillAppear` runs.
    private let viewWillAppearSubject = PassthroughSubject<Void, Never>()

    /// Fires each time `viewDidAppear` runs.
    private let viewDidAppearSubject = PassthroughSubject<Void, Never>()

    /// Lazily-constructed root content view; the `force_cast` is safe because
    /// `View: ContentView` and `ContentView: EmptyInitializable` by convention.
    private lazy var rootContentView: View =
        // swiftlint:disable:next force_cast
        (View.self as EmptyInitializable.Type).init() as! View

    // MARK: - Initialization

    /// Designated initializer. Coordinators call this with a freshly-constructed
    /// ViewModel; `setup()` wires the bindings eagerly so the View has live
    /// publishers before `viewDidLoad` runs.
    public required init(viewModel: ViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        setup()
    }

    /// Unavailable — Interface Builder is not supported. Traps to enforce the
    /// programmatic-only invariant.
    @available(*, unavailable)
    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }

    // MARK: View Lifecycle

    /// Sets up window chrome (background, root view, title, bar buttons, swipe-back),
    /// then fires the `viewDidLoad` lifecycle subject so the ViewModel's pipelines see it.
    ///
    /// Each opt-in protocol (`TitledScene`, `Right/LeftBarButtonContentMaking`,
    /// `BackButtonHiding`) is detected via runtime cast — there is no required
    /// override in subclasses, and absence is the no-op default.
    override open func viewDidLoad() {
        super.viewDidLoad()

        // App-wide background colour goes on the controller's view (visible behind
        // the content view during animations); content view is transparent so it
        // composes against this colour rather than masking it.
        view.backgroundColor = rootBackgroundColor
        rootContentView.backgroundColor = .clear
        view.addSubview(rootContentView)
        rootContentView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            rootContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            rootContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            rootContentView.topAnchor.constraint(equalTo: view.topAnchor),
            rootContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // Auto-set the navigation title only if a non-empty `TitledScene.title` is provided.
        // `case let sceneTitle = …` is just a destructuring binding — could be a plain `let`.
        if let titled = self as? TitledScene, case let sceneTitle = titled.sceneTitle, !sceneTitle.isEmpty {
            title = sceneTitle
        }

        // Opt-in static bar-button installation. Dynamic per-screen changes go
        // through the `…BarButtonContentSubject` instead (see `makeAndSubscribeToInputFromController`).
        if let rightButtonMaker = self as? RightBarButtonContentMaking {
            rightButtonMaker.setRightBarButton(for: self)
        }

        if let leftButtonMaker = self as? LeftBarButtonContentMaking {
            leftButtonMaker.setLeftBarButton(for: self)
        }

        // BackButtonHiding screens both hide the chevron AND disable interactive
        // pop — typically used on flow-terminating screens like a successful-create
        // confirmation, where backing up would re-enter an inconsistent state.
        if self is BackButtonHiding {
            navigationItem.hidesBackButton = true
        }

        navigationController?.interactivePopGestureRecognizer?.isEnabled = !(self is BackButtonHiding)

        // Last — fire the lifecycle pulse only after all chrome is in place,
        // so any view-model handler observing `viewDidLoad` can safely assume
        // the navigation bar is configured.
        viewDidLoadSubject.send(())
    }

    /// Re-applies the navigation bar layout (in case it was changed by a previous
    /// scene) and forwards the lifecycle event.
    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyLayoutIfNeeded()
        viewWillAppearSubject.send(())
    }

    /// Forwards the `viewDidAppear` lifecycle event to the ViewModel pipeline.
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewDidAppearSubject.send(())
    }
}

// MARK: Private

private extension SceneController {
    /// Called from the designated initializer. Currently a thin wrapper so
    /// future setup steps can be added without touching the init body.
    func setup() {
        bindViewToViewModel()
    }

    /// Constructs the ViewModel-facing `InputFromController`, eagerly subscribing
    /// the controller-side sinks (title text, toasts, dynamic bar-button updates)
    /// so the ViewModel can fire-and-forget those subjects.
    ///
    /// All sinks hop to `RunLoop.main` because they touch UIKit; `[weak self]`
    /// avoids a retain cycle with the long-lived controller-owned subjects.
    func makeAndSubscribeToInputFromController() -> InputFromController {
        let titleSubject = PassthroughSubject<String, Never>()
        let leftBarButtonContentSubject = PassthroughSubject<BarButtonContent, Never>()
        let rightBarButtonContentSubject = PassthroughSubject<BarButtonContent, Never>()
        let toastSubject = PassthroughSubject<Toast, Never>()
        // Snapshot the (overridable) clock at wiring time so the toast sink
        // closes over a single instance rather than re-resolving the
        // computed property on every emission.
        let clock = self.clock

        [
            // Dynamic title updates emitted by the ViewModel.
            titleSubject.receive(on: RunLoop.main).sink { [weak self] in self?.title = $0 },
            // Toasts are presented by the toast itself using `self` as the host VC.
            toastSubject.receive(on: RunLoop.main).sink { [weak self] in
                guard let self else { return }
                $0.present(using: self, clock: clock)
            },
            // Dynamic bar-button content swaps (e.g. enable/disable, change icon).
            leftBarButtonContentSubject.receive(on: RunLoop.main).sink { [weak self] in
                self?.setLeftBarButtonUsing(content: $0)
            },
            rightBarButtonContentSubject.receive(on: RunLoop.main).sink { [weak self] in
                self?.setRightBarButtonUsing(content: $0)
            },
        ].forEach { $0.store(in: &cancellables) }

        return InputFromController(
            viewDidLoad: viewDidLoadSubject.eraseToAnyPublisher(),
            viewWillAppear: viewWillAppearSubject.eraseToAnyPublisher(),
            viewDidAppear: viewDidAppearSubject.eraseToAnyPublisher(),
            leftBarButtonTrigger: leftBarButtonSubject.eraseToAnyPublisher(),
            rightBarButtonTrigger: rightBarButtonSubject.eraseToAnyPublisher(),
            titleSubject: titleSubject,
            leftBarButtonContentSubject: leftBarButtonContentSubject,
            rightBarButtonContentSubject: rightBarButtonContentSubject,
            toastSubject: toastSubject
        )
    }

    /// Performs the central wiring step:
    ///   View → InputFromView, Controller → InputFromController,
    ///   ViewModel.transform(_:) → Output, View.populate(with:) → bindings.
    /// Each cancellable returned by `populate` is stored so the bindings live as
    /// long as this controller does.
    func bindViewToViewModel() {
        let inputFromView = rootContentView.inputFromView
        let inputFromController = makeAndSubscribeToInputFromController()

        let input = ViewModel.Input(fromView: inputFromView, fromController: inputFromController)
        let output = viewModel.transform(input: input)

        rootContentView.populate(with: output).forEach { $0.store(in: &cancellables) }
    }

    /// Drives `NavigationBarLayoutingNavigationController` to apply the right
    /// nav-bar layout for the current scene each time it appears.
    ///
    /// Logic ladder:
    ///   1. No nav controller? Nothing to do.
    ///   2. Nav controller is the wrong class? That's a programming error — crash loudly.
    ///   3. Scene doesn't own a layout? No-op (the previous layout stays).
    ///   4. Same layout as last applied? Skip the work (avoid pointless animations).
    ///   5. Otherwise apply the new layout.
    func applyLayoutIfNeeded() {
        guard let navigationController else { return }
        guard let barLayoutingNavController = navigationController as? NavigationBarLayoutingNavigationController else {
            incorrectImplementation(
                "navigationController should be instance of `NavigationBarLayoutingNavigationController`"
            )
        }

        guard let barLayoutOwner = self as? NavigationBarLayoutOwner else {
            return
        }

        if let lastLayout = barLayoutingNavController.lastLayout {
            let layout = barLayoutOwner.navigationBarLayout
            guard layout != lastLayout else { return }
            barLayoutingNavController.applyLayout(layout)
        } else {
            barLayoutingNavController.applyLayout(barLayoutOwner.navigationBarLayout)
        }
    }
}
