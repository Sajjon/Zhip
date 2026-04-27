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

import Factory
import UIKit
import Zesame
import SingleLineControllerNavigation

/// Outcome of the Receive sub-flow.
enum ReceiveCoordinatorNavigationStep {
    /// User dismissed — `MainCoordinator` closes the modal.
    case finish
}

/// Coordinator owning the single-screen Receive (QR code) sub-flow.
/// Hosts a single `Receive` scene that shows the wallet's address as a QR code,
/// and adds a "share as link" action that builds a `zhip.app/send?...` deep link
/// via `DeepLinkGenerator` and presents the system share sheet.
final class ReceiveCoordinator: BaseCoordinator<ReceiveCoordinatorNavigationStep> {
    /// Builds outbound `zhip.app` URLs the share sheet uses.
    @Injected(\.deepLinkGenerator) private var deepLinkGenerator: DeepLinkGenerator

    /// Begins at the receive screen.
    override func start(didStart _: Completion? = nil) {
        toFirst()
    }
}

// MARK: - Navigate

private extension ReceiveCoordinator {
    /// Convenience wrapper for the entry point.
    func toFirst() {
        toReceive()
    }

    /// Pushes the receive screen. `.requestTransaction` opens the share sheet,
    /// `.finish` closes the modal.
    func toReceive() {
        let viewModel = ReceiveViewModel()

        push(scene: Receive.self, viewModel: viewModel) { [weak self] userDid in
            switch userDid {
            case let .requestTransaction(requestedTransaction): self?.share(transaction: requestedTransaction)
            case .finish: self?.finish()
            }
        }
    }

    /// Bubble `.finish` to the parent.
    func finish() {
        navigator.next(.finish)
    }
}

// MARK: - Share

private extension ReceiveCoordinator {
    /// Builds a `zhip.app/send?...` URL for the requested transaction and
    /// presents the system share sheet anchored on the right-bar item (so the
    /// popover arrow points the right way on iPad).
    func share(transaction: TransactionIntent) {
        let shareUrl = deepLinkGenerator.linkTo(transaction: transaction)
        let activityVC = UIActivityViewController(activityItems: [shareUrl], applicationActivities: nil)
        activityVC.modalPresentationStyle = .popover
        activityVC.popoverPresentationController?.barButtonItem = navigationController.navigationItem.rightBarButtonItem
        navigationController.present(activityVC, animated: true, completion: nil)
    }
}
