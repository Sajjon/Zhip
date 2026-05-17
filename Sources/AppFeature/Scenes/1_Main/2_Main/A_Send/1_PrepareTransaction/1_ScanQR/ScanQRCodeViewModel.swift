//
// MIT License
//
// Copyright (c) 2018-2026 Alexander Cyon (https://github.com/sajjon)
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

import Combine
import Foundation
import NanoViewControllerCombine
import NanoViewControllerCore
import NanoViewControllerController
import NanoViewControllerNavigation
import Zesame

// MARK: - User action and navigation steps

/// Outcomes of the QR-scan modal.
public enum ScanQRCodeUserAction: Sendable {
    /// User tapped Cancel.
    case cancel
    /// QR code scanned and successfully decoded into a `TransactionIntent`.
    case scanQRContainingTransaction(TransactionIntent)
}

// MARK: - ScanQRCodeViewModel

/// View model for the QR scanner. Decodes scanned strings into a
/// `TransactionIntent` and routes them upstream.
///
/// Accepts both raw JSON-payload QRs and ones prefixed with `zilliqa://`
/// (the QR scheme other Zilliqa wallets emit).
public final class ScanQRCodeViewModel: AbstractViewModel<
    ScanQRCodeViewModel.InputFromView,
    ScanQRCodeViewModel.Publishers,
    ScanQRCodeUserAction
> {
    /// Result type for the scan→decode pipeline.
    typealias ScannedQRResult = Result<TransactionIntent, Swift.Error>

    /// Currently unused side-channel for "start scanning" pulses (kept for
    /// future use if the reader needs an explicit start trigger).
    private let startScanningSubject = CurrentValueSubject<Void, Never>(())

    /// Decodes scanned strings, strips an optional `zilliqa://` prefix, and
    /// surfaces the resulting `TransactionIntent` (or cancel on bar-button tap).
    override public func transform(input: Input) -> Output<Publishers, NavigationStep> {
        let navigator = Navigator<NavigationStep>()

        let transactionIntentResult: AnyPublisher<ScannedQRResult, Never> = input.fromView.scannedQrCodeString.map {
            guard var stringFromQR = $0 else {
                return ScannedQRResult.failure(TransactionIntent.Error.scannedStringNotAddressNorJson)
            }

            let zilliqaPrefix = "zilliqa://"
            if stringFromQR.starts(with: zilliqaPrefix) {
                stringFromQR = String(stringFromQR.dropFirst(zilliqaPrefix.count))
            }

            do {
                return try ScannedQRResult.success(TransactionIntent.fromScannedQrCodeString(stringFromQR))
            } catch {
                return ScannedQRResult.failure(error)
            }
        }.eraseToAnyPublisher()

        let startScanningSubject = startScanningSubject

        return Output(
            publishers: Publishers(
                startScanning: startScanningSubject.replaceErrorWithEmpty().eraseToAnyPublisher()
            ),
            navigation: navigator.navigation
        ) {
            // MARK: Navigate

            input.fromController.leftBarButtonTrigger
                .sink { [navigator] in navigator.next(.cancel) }

            transactionIntentResult.sink { [navigator, startScanningSubject] in
                switch $0 {
                case .failure:
                    let toast = Toast(
                        String(localized: .ScanQRCode.incompatibleQRTitle),
                        dismissing: .manual(dismissButtonTitle: String(localized: .ScanQRCode.dismiss))
                    ) {
                        startScanningSubject.send(())
                    }
                    input.fromController.toastSubject.send(toast)
                case let .success(transactionIntent): navigator.next(.scanQRContainingTransaction(transactionIntent))
                }
            }
        }
    }
}

public extension ScanQRCodeViewModel {
    struct InputFromView {
        let scannedQrCodeString: AnyPublisher<String?, Never>
    }

    struct Publishers {
        let startScanning: AnyPublisher<Void, Never>
    }
}
