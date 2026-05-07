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

import AVFoundation
import Combine
import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerCore
import QRCodeReader
import UIKit

/// QR-code scanner view backed by the third-party `QRCodeReader` library.
/// Captures from the back camera and emits scanned strings through the view-model.
public final class ScanQRCodeView: UIView {
    /// Bridges the third-party reader's `didFindCode` callback into a Combine publisher.
    private let scannedQrCodeSubject = PassthroughSubject<String?, Never>()
    /// Library-provided viewfinder view.
    private lazy var readerView = QRCodeReaderView()
    /// Underlying QR-code reader (back camera, QR metadata only).
    private lazy var reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)

    public init() {
        super.init(frame: .zero)
        setup()
    }

    public required init?(coder _: NSCoder) {
        interfaceBuilderSucks
    }
}

private extension ScanQRCodeView {
    func setup() {
        reader.stopScanningWhenCodeIsFound = true
        readerView.backgroundColor = .black
        addSubview(readerView)
        readerView.translatesAutoresizingMaskIntoConstraints = false
        readerView.edgesToSuperview()
        readerView.setupComponents(with: QRCodeReaderViewControllerBuilder {
            $0.showCancelButton = false
            $0.showSwitchCameraButton = true
            $0.showTorchButton = true
            $0.showOverlayView = true
            $0.reader = reader
        })

        reader.didFindCode = { [weak self] in
            self?.scannedQrCodeSubject.send($0.value)
        }

        reader.didFailDecoding = { [weak self] in
            self?.scannedQrCodeSubject.send(nil)
        }

        readerView.switchCameraButton?.addTarget(
            self,
            action: #selector(switchCameraAction),
            for: .primaryActionTriggered
        )
        readerView.toggleTorchButton?.addTarget(
            self,
            action: #selector(toggleTorchAction),
            for: .primaryActionTriggered
        )
    }

    @objc func toggleTorchAction() {
        reader.toggleTorch()
    }

    @objc func switchCameraAction() {
        reader.switchDeviceInput()
    }
}

extension ScanQRCodeView: ViewModelled {
    public typealias ViewModel = ScanQRCodeViewModel

    public var inputFromView: InputFromView {
        InputFromView(
            scannedQrCodeString: scannedQrCodeSubject.replaceErrorWithEmpty().eraseToAnyPublisher()
        )
    }

    public func populate(with viewModel: ScanQRCodeViewModel.Output) -> [AnyCancellable] {
        [
            viewModel.startScanning.sink { [weak self] in
                self?.reader.startScanning()
            },
        ]
    }
}
