class SKOfferings {
  final List<SKOffering> offerings;

  SKOfferings({required this.offerings});

  SKOfferPackage? weeklyPackage() {
    try {
      return offerings.first.packages
          .firstWhere((package) => package.purchaseType == PurchaseType.weekly);
    } catch (_) {
      return null;
    }
  }

  SKOfferPackage? yearlyPackage() {
    try {
      return offerings.first.packages
          .firstWhere((package) => package.purchaseType == PurchaseType.yearly);
    } catch (_) {
      return null;
    }
  }

  factory SKOfferings.fromJson(Map<String?, dynamic> json) {
    final offeringsJson = json['offerings'] as List<dynamic>;
    final offerings = offeringsJson.map((offeringJson) {
      final packagesJson = offeringJson['packages'] as List<dynamic>;
      final packages = packagesJson.map((packageJson) {
        return SKOfferPackage(
          id: packageJson['id'] as String,
          description: packageJson['description'] as String,
          productId: packageJson['product_id'] as String,
          purchaseType: PurchaseTypeExtension.initWith(
              packageJson['purchase_type'] as String),
          priceString: packageJson['price_string'] as String,
          weeklyPriceString: packageJson['weekly_price_string'] as String?,
          dailyPriceString: packageJson['daily_price_string'] as String?,
          monthlyPriceString: packageJson['monthly_price_string'] as String?,
          introductoryPriceString:
              packageJson['introductory_price_string'] as String?,
          isTrial: packageJson['is_trial'] as bool,
          priceMicros: (packageJson['price_micros'] as num?)?.toInt(),
          currencyCode: packageJson['currency_code'] as String?,
          currencySymbol: packageJson['currency_symbol'] as String?,
          priceLocale: packageJson['price_locale'] as String?,
          periodUnit: packageJson['period_unit'] as String?,
          periodCount: (packageJson['period_count'] as num?)?.toInt(),
          introPriceMicros: (packageJson['intro_price_micros'] as num?)?.toInt(),
          introPaymentMode: packageJson['intro_payment_mode'] as String?,
          introPeriodUnit: packageJson['intro_period_unit'] as String?,
          introPeriodCount: (packageJson['intro_period_count'] as num?)?.toInt(),
        );
      }).toList();

      return SKOffering(
        id: offeringJson['id'] as String,
        description: offeringJson['description'] as String,
        packages: packages,
      );
    }).toList();

    return SKOfferings(offerings: offerings);
  }
}

class SKOffering {
  final String id;
  final String description;
  final List<SKOfferPackage> packages;

  SKOffering({
    required this.id,
    required this.description,
    required this.packages,
  });
}

enum PurchaseType {
  weekly,
  monthly,
  yearly,
  consumable,
  nonConsumable,
  unknown,
}

extension PurchaseTypeExtension on PurchaseType {
  static PurchaseType initWith(String string) {
    switch (string) {
      case "weekly":
        return PurchaseType.weekly;
      case "monthly":
        return PurchaseType.monthly;
      case "yearly":
        return PurchaseType.yearly;
      case "consumable":
        return PurchaseType.consumable;
      case "non-consumable":
        return PurchaseType.nonConsumable;
      default:
        return PurchaseType.unknown;
    }
  }
}

class SKOfferPackage {
  final String id;
  final String description;
  final String productId;
  final PurchaseType purchaseType;
  final String priceString;
  final String? weeklyPriceString;
  final String? dailyPriceString;
  final String? monthlyPriceString;
  final String? introductoryPriceString;
  final bool isTrial;

  // --- Raw store attributes (wire-generic primitives; consumers type them). ---
  /// Raw price in micros (price * 1_000_000).
  final int? priceMicros;

  /// ISO-4217 currency code (e.g. "USD").
  final String? currencyCode;

  /// Locale currency symbol (e.g. "$").
  final String? currencySymbol;

  /// Locale used to format the price (e.g. "pl_PL", "en-US") — for reformatting
  /// derived prices with the same CLDR rules.
  final String? priceLocale;

  /// Subscription period unit: "day" | "week" | "month" | "year".
  final String? periodUnit;

  /// Subscription period length in [periodUnit]s.
  final int? periodCount;

  /// Raw introductory-offer price in micros (null when there is no intro).
  final int? introPriceMicros;

  /// Intro payment mode: "free_trial" | "pay_as_you_go" | "pay_up_front".
  final String? introPaymentMode;

  /// Intro period unit ("day" | "week" | "month" | "year").
  final String? introPeriodUnit;

  /// Intro period length in [introPeriodUnit]s.
  final int? introPeriodCount;

  SKOfferPackage({
    required this.id,
    required this.description,
    required this.productId,
    required this.purchaseType,
    required this.priceString,
    required this.weeklyPriceString,
    required this.dailyPriceString,
    required this.monthlyPriceString,
    required this.introductoryPriceString,
    required this.isTrial,
    this.priceMicros,
    this.currencyCode,
    this.currencySymbol,
    this.priceLocale,
    this.periodUnit,
    this.periodCount,
    this.introPriceMicros,
    this.introPaymentMode,
    this.introPeriodUnit,
    this.introPeriodCount,
  });
}

extension PurchasePriceExtension on SKOfferPackage {
  String get effectivePrice {
    switch (purchaseType) {
      case PurchaseType.weekly:
        return weeklyPriceString ?? priceString;
      case PurchaseType.monthly:
        return monthlyPriceString ?? priceString;
      default:
        return priceString;
    }
  }
}

