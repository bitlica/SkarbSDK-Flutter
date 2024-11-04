//
//  SKOfferings+ToJson.swift
//  skarb_plugin
//
//  Created by Viktor Starikov on 14.11.2023.
//

import Foundation
import SkarbSDK
import StoreKit

extension SKOfferings {
    func toJson() -> [String: Any] {
        return [
            "offerings": offerings.map { $0.toJson() }
        ]
    }
}

extension SKOffering {
    func toJson() -> [String: Any] {
        return [
            "id": id,
            "description": description,
            "packages": packages.map { $0.toJson() }
        ]
    }
}

extension SKOfferPackage {
    func toJson() -> [String: Any] {
        // TODO remove dailyPriceString calculation use new Skarb version 0.6.19 (call dailyLocalizedPriceString function) (start)
        let multiplier = switch purchaseType {
           case .weekly: 7
           case .monthly: 30
           case .yearly: 365
           case .consumable: 1
           case .nonConsumable: 1
           case .unknown: 1
        }

        let dailyPriceString = localizedPriceWithMultiplier(1 / Double(multiplier));

        // TODO remove dailyPriceString calculation use new Skarb version 0.6.19 (call dailyLocalizedPriceString function) (end)
        return [
            "id": id,
            "description": description,
            "product_id": productId,
            "purchase_type": purchaseType.toString(),
            "price_string": localizedPriceString,
            "weekly_price_string": weeklyLocalizedPriceString as Any,
            "daily_price_string": dailyPriceString,
            "is_trial": isTrial
        ]
    }
}

extension PurchaseType {
    func toString() -> String {
        switch self {
        case .weekly:
            return "weekly"
        case .monthly:
            return "monthly"
        case .yearly:
            return "yearly"
        case .consumable:
            return "consumable"
        case .nonConsumable:
            return "non-consumable"
        case .unknown:
            return "unknown"
        }
    }
}
