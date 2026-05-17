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
import Factory
import Foundation
import NanoViewControllerCombine
import NanoViewControllerController
import NanoViewControllerCore
import Validation
 import Zesame

// MARK: - PrepareTransactionUserAction

/// Outcomes of step 1 of Send.
public enum PrepareTransactionUserAction: Sendable {
    /// User tapped the right-bar Cancel.
    case cancel
    /// User submitted a fully-validated payment for review (advances to step 2).
    case reviewPayment(Payment)
    /// User tapped the QR-scan icon — coordinator presents the scanner modal.
    case scanQRCode
}

// MARK: - PrepareTransactionViewModel

/// View model for step 1 of Send. Handles four parallel concerns:
/// - balance fetch (with pull-to-refresh + cached-balance fallback);
/// - real-time per-field validation (recipient, amount, gas limit, gas price);
/// - cross-field "sufficient funds" check;
/// - pre-fill from inbound `TransactionIntent` (deep-link or QR scan).
public final class PrepareTransactionViewModel: BaseViewModel<// swiftlint:disable:this type_body_length
    PrepareTransactionUserAction,
    PrepareTransactionViewModel.InputFromView,
    PrepareTransactionViewModel.Publishers
> {
    /// Network façade for balance + gas-price fetches.
    @Injected(\.transactionsUseCase) private var transactionUseCase: TransactionsUseCase
    /// Wallet source for the recipient/amount/balance pipeline.
    @Injected(\.walletStorageUseCase) private var walletStorageUseCase: WalletStorageUseCase

    /// Pre-fill source — merged stream of QR-scanned and deep-linked intents from the coordinator.
    private let scannedOrDeeplinkedTransaction: AnyPublisher<TransactionIntent, Never>

    /// Captures the pre-fill source.
    init(scannedOrDeeplinkedTransaction: AnyPublisher<TransactionIntent, Never>) {
        self.scannedOrDeeplinkedTransaction = scannedOrDeeplinkedTransaction
    }

    // swiftlint:disable:next function_body_length
    override public func transform(input: Input) -> Output<Publishers, NavigationStep> {
        func userIntends(to intention: NavigationStep) {
            navigator.next(intention)
        }

        let wallet = walletStorageUseCase.wallet.filterNil().replaceErrorWithEmpty()
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()

        let fetchTrigger = input.fromView.pullToRefreshTrigger.merge(with: wallet.mapToVoid()).eraseToAnyPublisher()

        // Fetch latest balance from API
        let latestBalanceAndNonce: AnyPublisher<BalanceResponse, Never> = fetchTrigger.withLatestFrom(wallet)
            .flatMapLatest {
                self.transactionUseCase
                    .getBalance(for: $0.legacyAddress)
                    .trackActivity(activityIndicator)
                    .trackError(errorTracker)
                    .replaceErrorWithEmpty()
                    .handleEvents(receiveOutput: { [weak self] in
                        self?.transactionUseCase.cacheBalance($0.balance)
                    })
            }
            .eraseToAnyPublisher()

        // Do NOT `prepend(0)`. Without a real network nonce the Review button
        // would enable on a stale 0 — the network rejects nonce-too-low and
        // the user gets a confusing error mid-Send. The downstream `payment`
        // construction stays nil until the first balance fetch lands, which
        // also keeps the Review CTA disabled until the network is reachable.
        let nonce = latestBalanceAndNonce.map(\.nonce)
        let startingBalance: Amount = transactionUseCase.cachedBalance ?? 0
        let balance: AnyPublisher<Amount, Never> = latestBalanceAndNonce.map(\.balance).prepend(startingBalance)
            .eraseToAnyPublisher()

        // MARK: - VALIDATION -> VALUE

        let validator = InputValidator()

        // MARK: Recipient Input ->  Value + Validation

        let recipientValidationValue: AnyPublisher<Validation<Address, AddressValidator.Error>, Never> = input.fromView
            .recipientAddress
            .map { validator.validateRecipient($0) }
            .merge(with: scannedOrDeeplinkedTransaction.map { .valid($0.to) })
            .eraseToAnyPublisher()

        let recipient: AnyPublisher<Address?, Never> = recipientValidationValue.map(\.value).eraseToAnyPublisher()

        let recipientValidationTrigger = input.fromView.didEndEditingRecipientAddress

        let recipientValidation: AnyPublisher<AnyValidation, Never> = recipientValidationTrigger
            .withLatestFrom(recipientValidationValue)
            .onlyErrors()
            .merge(with: recipientValidationValue.nonErrors())
            .eraseToAnyPublisher()

        // MARK: GasLimit + GasPrice Input -> Value + Validation

        let _startingGasLimit = GasLimit.minimum
        let gasLimitValidationValue = input.fromView.gasLimit.map { validator.validateGasLimit($0) }
            .prepend(.valid(_startingGasLimit))
            .eraseToAnyPublisher()
        let gasLimit: AnyPublisher<GasLimit?, Never> = gasLimitValidationValue.map(\.value).eraseToAnyPublisher()

        let _startingGasPrice: GasPrice = .min
        let gasPriceValidationValue = input.fromView.gasPrice.map { validator.validateGasPrice($0) }
            .prepend(.valid(_startingGasPrice))
            .eraseToAnyPublisher()

        let gasPrice: AnyPublisher<GasPrice?, Never> = gasPriceValidationValue.map(\.value).eraseToAnyPublisher()

        let maxAmountTrigger = input.fromView.maxAmountTrigger

        let gasLimitValidationErrorTrigger: AnyPublisher<Void, Never> = input.fromView.didEndEditingGasLimit
            .merge(with: maxAmountTrigger).eraseToAnyPublisher()

        let gasLimitValidation = gasLimitValidationErrorTrigger.withLatestFrom(gasLimitValidationValue).onlyErrors()
            .merge(with: gasLimitValidationValue.nonErrors()).eraseToAnyPublisher()

        let gasPriceValidationErrorTrigger: AnyPublisher<Void, Never> = input.fromView.didEndEditingGasPrice
            .merge(with: maxAmountTrigger).eraseToAnyPublisher()

        let gasPriceValidation = gasPriceValidationErrorTrigger.withLatestFrom(gasPriceValidationValue).onlyErrors()
            .merge(with: gasPriceValidationValue.nonErrors()).eraseToAnyPublisher()

        let zilAmountFromScannedOrDeeplinkedTransaction: AnyPublisher<AmountValidator<Amount>.ValidationResult, Never> =
            scannedOrDeeplinkedTransaction.map(\.amount).filterNil().map { .valid(.amount(
                $0,
                in: .zil
            )) }.eraseToAnyPublisher()

        // MARK: Amount + MaxAmountTrigger Input -> Value + Validation

        let amountWithoutSufficientFundsCheckValidationValue: AnyPublisher<
            AmountValidator<Amount>.ValidationResult,
            Never
        > =
            input.fromView.amountToSend.map { validator.validateAmount($0) }
                .merge(with: zilAmountFromScannedOrDeeplinkedTransaction).eraseToAnyPublisher()

        let amountWithoutSufficientFundsCheck: AnyPublisher<Amount?, Never> =
            amountWithoutSufficientFundsCheckValidationValue
                .map { $0.value?.amount }.eraseToAnyPublisher()

        let amountValidationValue: AnyPublisher<
            SufficientFundsValidator.ValidationResult,
            Never
        > = // Input from fields or deeplinked/scanned
            amountWithoutSufficientFundsCheck.merge(with: // Max trigger -> Balance SUBTRACT GasPrice (default to min)
                maxAmountTrigger.withLatestFrom(
                    balance.prepend(startingBalance).combineLatest(
                        gasLimit.prepend(_startingGasLimit),
                        gasPrice.prepend(_startingGasPrice)
                    ) { (
                        latestBalance: Amount?,
                        latestGasLimit: GasLimit?,
                        latestGasPrice: GasPrice?
                    ) -> Amount? in
                        let balanceOrZero: Amount = latestBalance ?? startingBalance
                        let gasLimitOrMin: GasLimit = latestGasLimit ?? _startingGasLimit
                        let gasPriceOrMin: GasPrice = latestGasPrice ?? _startingGasPrice

                        guard let balanceMinusGas: Amount = try? balanceOrZero - Payment
                            .estimatedTotalTransactionFee(
                                gasPrice: gasPriceOrMin,
                                gasLimit: gasLimitOrMin
                            )
                        else {
                            return nil
                        }
                        return balanceMinusGas
                    }.eraseToAnyPublisher()
                ) { $1 })
            .combineLatest(
                gasLimit.prepend(_startingGasLimit),
                gasPrice.prepend(_startingGasPrice),
                balance.prepend(startingBalance)
            ) { (amount: Amount?, gasLimit: GasLimit?, gasPrice: GasPrice?, balance: Amount?) in
                validator.validate(amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, lessThanBalance: balance)
            }.eraseToAnyPublisher()

        let amountBoundByBalance: AnyPublisher<Amount?, Never> = amountValidationValue.map(\.value)
            .eraseToAnyPublisher()

        let amountValidationErrorTrigger: AnyPublisher<Void, Never> = Combine.Publishers.Merge3(
            input.fromView.didEndEditingAmount,
            scannedOrDeeplinkedTransaction.mapToVoid(),
            gasPriceValidationValue.mapToVoid()
        ).eraseToAnyPublisher()

        let amountValidation: AnyPublisher<AnyValidation, Never> = amountValidationErrorTrigger
            .withLatestFrom(amountValidationValue)
            .map { AnyValidation($0) }
            .merge(with: amountValidationValue.nonErrors())
            .eraseToAnyPublisher()

        let payment: AnyPublisher<Payment?, Never> = recipient
            .combineLatest(amountBoundByBalance, gasLimit, gasPrice)
            .combineLatest(nonce) { tuple, n -> Payment? in
                let (r, a, gl, gp) = tuple
                guard let to = try? r?.toChecksummedLegacyAddress(), let amount = a, let gasLimit = gl,
                      let gasPrice = gp
                else {
                    return nil
                }
                do {
                    return try Payment(to: to, amount: amount, gasLimit: gasLimit, gasPrice: gasPrice, nonce: n)
                } catch {
                    print(error)
                    return nil
                }
            }
            .eraseToAnyPublisher()

        // Setup navigation
        [
            input.fromController.rightBarButtonTrigger
                .sink { userIntends(to: .cancel) },

            input.fromView.scanQRTrigger
                .sink { userIntends(to: .scanQRCode) },

            input.fromView.toReviewTrigger.withLatestFrom(payment.filterNil())
                .sink { userIntends(to: .reviewPayment($0)) },
        ].forEach { $0.store(in: &cancellables) }

        // MARK: FORMATTING

        let formatter = AmountFormatter()
        let balanceFormatted: AnyPublisher<String, Never> = balance.map { formatter.format(
            amount: $0,
            in: .zil,
            formatThousands: true,
            showUnit: true
        ) }.eraseToAnyPublisher()

        // The displayed recipient string is the raw parsed address. NOTE: the
        // `payment` construction above silently checksums via
        // `toChecksummedLegacyAddress()`, so the user is *not* warned about
        // unchecksummed input today. If we want to surface that, gate `payment`
        // on a deliberate "did you mean…?" confirmation step instead of auto
        // -correcting in the background.
        let recipientFormatted: AnyPublisher<String, Never> = recipient.filterNil().map(\.asString)
            .eraseToAnyPublisher()

        let amountFormatted: AnyPublisher<String?, Never> = amountBoundByBalance.filterNil()
            .map { formatter.format(amount: $0, in: .zil, formatThousands: false) as String? }
            .ifEmpty(switchTo: amountWithoutSufficientFundsCheckValidationValue.map {
                guard let value = $0.value else { return nil }
                switch value {
                case let .string(string): return string
                case let .amount(amount, _):
                    return formatter.format(amount: amount, in: .zil, formatThousands: false)
                }
            }.eraseToAnyPublisher())
            .eraseToAnyPublisher()

        let isReviewButtonEnabled: AnyPublisher<Bool, Never> = payment.map { $0 != nil }.eraseToAnyPublisher()

        let gasLimitPlaceholder: AnyPublisher<String, Never> = Just(GasLimit.minimum).map {
            String(localized: .PrepareTransaction.gasLimitField(minimum: $0.description))
        }.eraseToAnyPublisher()

        let gasPricePlaceholder: AnyPublisher<String, Never> = Just(GasPrice.min).map {
            String(localized: .PrepareTransaction.gasPriceField(
                minQa: formatter.format(amount: $0, in: .li, formatThousands: true, showUnit: false),
                minZil: formatter.format(amount: $0, in: .zil, formatThousands: true, showUnit: true)
            ))
        }.eraseToAnyPublisher()

        let gasLimitFormatted: AnyPublisher<String, Never> = gasLimit.filterNil().map(\.description)
            .eraseToAnyPublisher()
        let gasPriceFormatted: AnyPublisher<String, Never> = gasPrice.filterNil()
            .map { formatter.format(amount: $0, in: .li, formatThousands: true) }
            .eraseToAnyPublisher()

        let balanceWasUpdatedAt: AnyPublisher<Date?, Never> = fetchTrigger.map { [weak self] _ -> Date? in
            self?.transactionUseCase.balanceUpdatedAt
        }.eraseToAnyPublisher()

        let refreshControlLastUpdatedTitle: AnyPublisher<String, Never> = balanceWasUpdatedAt.map {
            BalanceLastUpdatedFormatter().string(from: $0)
        }.eraseToAnyPublisher()

        let setAmountInViewTrigger = input.fromView.maxAmountTrigger
            .merge(with: scannedOrDeeplinkedTransaction.mapToVoid()).eraseToAnyPublisher()

        let setAmountInViewOnlyByExternalTrigger = setAmountInViewTrigger.withLatestFrom(amountFormatted)
            .eraseToAnyPublisher()

        return Output(
            publishers: Publishers(
                refreshControlLastUpdatedTitle: refreshControlLastUpdatedTitle,
                isFetchingBalance: activityIndicator.asPublisher(),
                isReviewButtonEnabled: isReviewButtonEnabled,
                balance: balanceFormatted,

                recipient: recipientFormatted,
                recipientAddressValidation: recipientValidation,

                amountPlaceholder: Just(String(localized: .PrepareTransaction.amountField(unit: Unit.zil.displayName)))
                    .eraseToAnyPublisher(),
                amount: setAmountInViewOnlyByExternalTrigger,
                amountValidation: amountValidation,

                gasLimitMeasuredInLi: gasLimitFormatted,
                gasLimitPlaceholder: gasLimitPlaceholder,
                gasLimitValidation: gasLimitValidation,

                gasPriceMeasuredInLi: gasPriceFormatted,
                gasPricePlaceholder: gasPricePlaceholder,
                gasPriceValidation: gasPriceValidation,

                costOfTransaction: gasLimit.combineLatest(gasPrice).eraseToAnyPublisher().flatMapLatest {
                    (gl: GasLimit?, gp: GasPrice?) -> AnyPublisher<String?, Never> in
                    guard let gasLimit = gl else {
                        return AnyPublisher<String?, Never>.just(nil)
                    }
                    guard let gasPrice = gp else {
                        return AnyPublisher<String?, Never>.just(nil)
                    }
                    return
                        // The `eraseToAnyPublisher()` here is load-bearing — without
                        // it, Swift's overload resolution sees two viable
                        // `compactMap` overloads (the tuple-arg version on `Just<(_, _)>`
                        // and the standard Publisher one) and emits an ambiguity
                        // error. Erasing first collapses to the Publisher overload.
                        Just((gasPrice, gasLimit)).eraseToAnyPublisher()
                        .compactMap { try? Payment.estimatedTotalTransactionFee(gasPrice: $0, gasLimit: $1) }
                        .map { formatter.format(amount: $0, in: .zil, formatThousands: true, showUnit: true) }
                        .map { String(localized: .PrepareTransaction.transactionFeeLabel(fee: $0)) }
                        .eraseToAnyPublisher()
                }
                .eraseToAnyPublisher()
            ),
            navigation: navigator.navigation
        )
    }
}

public extension PrepareTransactionViewModel {
    struct InputFromView {
        let pullToRefreshTrigger: AnyPublisher<Void, Never>
        let scanQRTrigger: AnyPublisher<Void, Never>
        let maxAmountTrigger: AnyPublisher<Void, Never>
        let toReviewTrigger: AnyPublisher<Void, Never>

        let recipientAddress: AnyPublisher<String, Never>
        let didEndEditingRecipientAddress: AnyPublisher<Void, Never>

        let amountToSend: AnyPublisher<String, Never>
        let didEndEditingAmount: AnyPublisher<Void, Never>

        let gasLimit: AnyPublisher<String, Never>
        let didEndEditingGasLimit: AnyPublisher<Void, Never>

        let gasPrice: AnyPublisher<String, Never>
        let didEndEditingGasPrice: AnyPublisher<Void, Never>
    }

    struct Publishers {
        let refreshControlLastUpdatedTitle: AnyPublisher<String, Never>
        let isFetchingBalance: AnyPublisher<Bool, Never>
        let isReviewButtonEnabled: AnyPublisher<Bool, Never>
        let balance: AnyPublisher<String, Never>

        let recipient: AnyPublisher<String, Never>
        let recipientAddressValidation: AnyPublisher<AnyValidation, Never>

        let amountPlaceholder: AnyPublisher<String, Never>
        let amount: AnyPublisher<String?, Never>
        let amountValidation: AnyPublisher<AnyValidation, Never>

        let gasLimitMeasuredInLi: AnyPublisher<String, Never>
        let gasLimitPlaceholder: AnyPublisher<String, Never>
        let gasLimitValidation: AnyPublisher<AnyValidation, Never>

        let gasPriceMeasuredInLi: AnyPublisher<String, Never>
        let gasPricePlaceholder: AnyPublisher<String, Never>
        let gasPriceValidation: AnyPublisher<AnyValidation, Never>

        let costOfTransaction: AnyPublisher<String?, Never>
    }
}

// MARK: - Field Validation

extension PrepareTransactionViewModel {
    struct InputValidator {
        private let addressValidator = AddressValidator()
        private let zilAmountValidator = AmountValidator<Amount>()
        private let gasPriceValidator = GasPriceValidator()
        private let gasLimitValidator = GasLimitValidator()
        private let sufficientFundsValidator = SufficientFundsValidator()

        func validateRecipient(_ recipient: String?) -> AddressValidator.ValidationResult {
            addressValidator.validate(input: recipient)
        }

        func validate(
            amount: Amount?,
            gasLimit: GasLimit?,
            gasPrice: GasPrice?,
            lessThanBalance balance: Amount?
        ) -> SufficientFundsValidator.ValidationResult {
            sufficientFundsValidator.validate(input: (amount, gasLimit, gasPrice, balance))
        }

        func validateAmount(_ amount: String) -> AmountValidator<Amount>.ValidationResult {
            zilAmountValidator.validate(input: (amount, Zesame.Unit.zil))
        }

        func validateGasLimit(_ gasLimit: String?) -> GasLimitValidator.ValidationResult {
            gasLimitValidator.validate(input: gasLimit)
        }

        func validateGasPrice(_ gasPrice: String?) -> GasPriceValidator.ValidationResult {
            gasPriceValidator.validate(input: gasPrice)
        }
    }
}
