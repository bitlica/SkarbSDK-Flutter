//
//  SKUserPurchaseInfo+Json.swift
//  skarb_plugin
//
//  Created by Viktor Starikov on 06.08.2024.
//

import Foundation
import SkarbSDK
import StoreKit

extension SKUserPurchaseInfo {
    func toJson() -> [String: Any] {
        return [
            "environment": environment,
            "purchasedSubscriptions": purchasedSubscriptions.map { $0.toJson() },
            "onetimePurchases": onetimePurchases.map { $0.toJson() },
        ]
    }
}

extension SKPurchasedSubscription {
    func toJson() -> [String: Any] {
        return [
            "transactionID": transactionID,
            "originalTransactionID": originalTransactionID,
            "expiryDate": expiryDate.timeIntervalSince1970,
            "productID": productID,
            "quantity": quantity,
            "introOfferPeriod": introOfferPeriod,
            "trialPeriod": trialPeriod,
            "renewalInfo": renewalInfo,
        ]
    }
}

extension SKOnetimePurchase {
    func toJson() -> [String: Any] {
        return [
            "transactionID": transactionID,
            "purchaseDate": purchaseDate.timeIntervalSince1970,
            "productID": productID,
            "quantity": quantity,
        ]
    }
}
