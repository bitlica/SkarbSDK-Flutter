//
//  BitlicaSkarbManager.swift
//

import Foundation
import SkarbSDK
import StoreKit

public protocol BitlicaSkarbManagerDelegate: AnyObject {
    func storeKitUpdatedTransaction(_ updatedTransaction: SKPaymentTransaction)
    func storeKit(shouldAddStorePayment payment: SKPayment,
                  for product: SKProduct) -> Bool
}

public typealias UserPurchasesInfoResult = (Result<SKUserPurchaseInfo, Error>) -> Void

public protocol BitlicaSkarbManager: AnyObject {
    var hasAvailablePackages: Bool { get }
    var offerings: SKOfferings? { get }
    var packages: [SKOfferPackage]? { get }
    var canMakePurchases: Bool { get }
    var isPremium: Bool { get }
    var userPurchasesInfoWasUpdated: Notification.Name { get }
    var delegate: BitlicaSkarbManagerDelegate? { get set }
    var userPurchasesInfo: SKUserPurchaseInfo? { get }

    func fetchPackages(by productIDs: [String]) -> [SKOfferPackage]
    func requestOffering(
        with refreshPolicy: SKRefreshPolicy,
        completion: @escaping (Error?) -> Void
    )
    func restorePurchases(completion: @escaping UserPurchasesInfoResult)
    func purchase(
        package: SKOfferPackage,
        eventParams: [String: Any],
        completion: @escaping UserPurchasesInfoResult
    )
    func fetchUserPurchasesInfo(
        with refreshPolicy: SKRefreshPolicy,
        completion: @escaping UserPurchasesInfoResult
    )
    func fetchPurchasedSubscription(by productId: String) -> SKPurchasedSubscription?
}


public class BitlicaSkarbManagerImplementation: BitlicaSkarbManager {

    // Single source of truth for the notification name posted by this
    // manager whenever its cached `userPurchasesInfo` refreshes. Exposed as
    // a typed `Notification.Name` so observers (e.g. the Flutter event-
    // channel forwarder) don't repeat the raw string and risk drift.
    public static let userPurchasesInfoDidUpdateNotification: Notification.Name =
        Notification.Name("SubscriptionValidWasUpdated")

    // MARK: Public (Properties)
    public var hasAvailablePackages: Bool {
        packages?.isEmpty == false
    }
    public var offerings: SKOfferings?
    public var packages: [SKOfferPackage]?
    public var canMakePurchases: Bool {
        SkarbSDK.canMakePayments()
    }

    public var isPremium: Bool {
        guard let userPurchasesInfo else { return false }

        let lifetimePurchases = userPurchasesInfo.onetimePurchases.filter {
            $0.productID.contains("lifetime")
        }

        return userPurchasesInfo.isActiveSubscription || !lifetimePurchases.isEmpty
    }

    public var userPurchasesInfoWasUpdated: Notification.Name {
        Self.userPurchasesInfoDidUpdateNotification
    }

    public weak var delegate: BitlicaSkarbManagerDelegate?

    public var userPurchasesInfo: SKUserPurchaseInfo?

    //  MARK: Private (Properties)
    private var purchaseEventParams: [String: Any]?
    private let observerBag = NotificationObserverBag()

    //  MARK: Init

    public init(
        clientId: String,
        isObservable: Bool,
        deviceId: String?
    ) {
        SkarbSDK.initialize(
            clientId: clientId,
            isObservable: isObservable,
            deviceId: deviceId
        )
        SkarbSDK.setStoreKitDelegate(self)
        // Pick up SDK-driven cache refreshes (e.g. background receipt
        // re-validation) that don't flow through our own
        // purchase/restore/validate callbacks. The SDK posts this only
        // after it has just persisted a fresh snapshot, so reading the
        // cache here returns the new value, not a stale one.
        observerBag.add(NotificationCenter.default.addObserver(
            forName: .skarbUserPurchaseInfoDidUpdate,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.userPurchasesInfo =
                SkarbSDK.getCachedUserPurchaseInfoIfAvailable()
            NotificationCenter.default.post(
                name: self.userPurchasesInfoWasUpdated,
                object: nil
            )
        })
        fetchUserPurchasesInfo(with: .always) { [weak self] result in
            guard let self = self else { return }
        }
    }

    // MARK: - Public (Interface)
    public func fetchPackages(by productIDs: [String]) -> [SKOfferPackage] {
        productIDs.compactMap({ getPackage(by: $0) })
    }

    /// Might be called on the any thread. Callback will be on the main thread
    public func requestOffering(
        with refreshPolicy: SKRefreshPolicy,
        completion: @escaping (Error?) -> Void
    ) {
        SkarbSDK.getOfferings(with: refreshPolicy) { [weak self] result in
            guard let self = self else {
                return
            }
            switch result {
            case .success(let updatedOfferings):
                self.offerings = updatedOfferings
                self.packages = updatedOfferings.allOfferingPackages
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
    }

    /// Restore all purchases
    /// Should be called on the main thread. Callback will be on the main thread
    /// - Note: This may force your users to enter the App Store password so should only be performed on request of
    /// the user. Typically with a button in settings or near your purchase UI.
    public func restorePurchases(completion: @escaping UserPurchasesInfoResult) {
        SkarbSDK.restorePurchases { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let updatedUserPurchaseInfo):
                self.needToUpdateUserPurchasesInfo(updatedUserPurchaseInfo)
                completion(.success(updatedUserPurchaseInfo))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    /// Should be called on the main thread. Callback will be on the main thread
    public func purchase(
        package: SKOfferPackage,
        eventParams: [String: Any],
        completion: @escaping UserPurchasesInfoResult
    ) {
        purchaseEventParams = eventParams
        SkarbSDK.purchasePackage(package, completion: { [weak self] result in
            guard let self = self else { return }
            if case let .success(updatedUserPurchaseInfo) = result {
                self.needToUpdateUserPurchasesInfo(updatedUserPurchaseInfo)
            }
            self.handlePurchase(with: result)
            completion(result)
        })
    }

    /// Verify receipt for user purchases.
    /// Might be called on the any thread. Callback will be on the main thread
    public func fetchUserPurchasesInfo(
        with refreshPolicy: SKRefreshPolicy,
        completion: @escaping UserPurchasesInfoResult
    ) {
        SkarbSDK.validateReceipt(with: refreshPolicy,
                                 completion: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let updatedUserPurchaseInfo):
                self.needToUpdateUserPurchasesInfo(updatedUserPurchaseInfo)
                completion(.success(updatedUserPurchaseInfo))
            case .failure(let failure):
                completion(.failure(failure))
            }
        })
    }

    public func fetchPurchasedSubscription(by productId: String) -> SKPurchasedSubscription? {
        return userPurchasesInfo?.fetchPurchasedSubscription(by: productId)
    }

    // MARK: Private (Interface)
    private func getPackage(by productId: String) -> SKOfferPackage? {
        packages?.first { $0.productId == productId }
    }

    private func handlePurchase(with result: Result<SKUserPurchaseInfo, any Error>) {
        guard let purchaseEventParams else {
            return
        }
        self.purchaseEventParams = nil
    }

    private func needToUpdateUserPurchasesInfo(_ userPurchasesInfo: SKUserPurchaseInfo) {
        self.userPurchasesInfo = userPurchasesInfo
        NotificationCenter.default.post(name: userPurchasesInfoWasUpdated, object: nil)
    }
}

// MARK: SKStoreKitDelegate
extension BitlicaSkarbManagerImplementation: SKStoreKitDelegate {
    public func storeKitUpdatedTransaction(_ updatedTransaction: SKPaymentTransaction) {
        delegate?.storeKitUpdatedTransaction(updatedTransaction)
        switch updatedTransaction.transactionState {
        case .purchasing:
            guard let purchaseEventParams else {
                return
            }
        case .deferred:
            guard let purchaseEventParams else {
                return
            }
        default:
            break
        }
    }

    public func storeKit(shouldAddStorePayment payment: SKPayment,
                         for product: SKProduct) -> Bool {
        return delegate?.storeKit(shouldAddStorePayment: payment, for: product) ?? false
    }
}

