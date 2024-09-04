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
          isTrial: packageJson['is_trial'] as bool,
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
  final bool isTrial;

  SKOfferPackage({
    required this.id,
    required this.description,
    required this.productId,
    required this.purchaseType,
    required this.priceString,
    required this.weeklyPriceString,
    required this.dailyPriceString,
    required this.isTrial,
  });
}
