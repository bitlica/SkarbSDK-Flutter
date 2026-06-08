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
            "packages": packages.map { $0.toJson() },
        ]
    }
}

extension SKOfferPackage {
    func toJson() -> [String: Any] {
        var json: [String: Any] = [
            "id": id,
            "description": description,
            "product_id": productId,
            "purchase_type": purchaseType.toString(),
            "price_string": localizedPriceString,
            "weekly_price_string": weeklyLocalizedPriceString as Any,
            "daily_price_string": dailyLocalizedPriceString as Any,
            "monthly_price_string": monthlyLocalizedPriceString as Any,
            "introductory_price_string": localizedIntroductoryPriceString as Any,
            "is_trial": isTrial,
        ]

        // Raw attributes for paywall tag resolution (typed at the screen-builder
        // consumer). The Android plugin sends the same keys.
        json["price_micros"] = (storeProduct.price as NSDecimalNumber)
            .multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value
        // Currency from the store's locale (App Store storefront), not device locale.
        if let code = storeProduct.priceLocale.currencyCode {
            json["currency_code"] = code
        }
        if let symbol = storeProduct.priceLocale.currencySymbol {
            json["currency_symbol"] = symbol
        }
        // Locale used to format the price — lets the consumer reformat derived
        // prices (increased / per-year / intro) with the same CLDR rules.
        json["price_locale"] = storeProduct.priceLocale.identifier

        if #available(iOS 11.2, *) {
            if let period = storeProduct.subscriptionPeriod {
                if let unit = period.unit.sbPeriodString {
                    json["period_unit"] = unit
                }
                json["period_count"] = period.numberOfUnits
            }
            if let intro = storeProduct.introductoryPrice {
                json["intro_price_micros"] = (intro.price as NSDecimalNumber)
                    .multiplying(by: NSDecimalNumber(value: 1_000_000)).int64Value
                json["intro_payment_mode"] = intro.paymentMode.sbModeString
                if let unit = intro.subscriptionPeriod.unit.sbPeriodString {
                    json["intro_period_unit"] = unit
                }
                json["intro_period_count"] = intro.subscriptionPeriod.numberOfUnits
            }
        }

        return json
    }
}

@available(iOS 11.2, *)
private extension SKProduct.PeriodUnit {
    /// Wire-string for the subscription period unit ("day"/"week"/"month"/"year").
    var sbPeriodString: String? {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return nil
        }
    }
}

@available(iOS 11.2, *)
private extension SKProductDiscount.PaymentMode {
    /// Wire-string for the intro payment mode. Mirrors the Android plugin values.
    var sbModeString: String {
        switch self {
        case .freeTrial: return "free_trial"
        case .payAsYouGo: return "pay_as_you_go"
        case .payUpFront: return "pay_up_front"
        @unknown default: return "pay_as_you_go"
        }
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
