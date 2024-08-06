abstract class SkarbPurchaseInfo {}

class SkarbPurchaseInfoAndroid extends SkarbPurchaseInfo {}

class SkarbPurchaseInfoIOS extends SkarbPurchaseInfo {
  final String environment;
  final List<SkarbPurchasedSubscriptionIOS> purchasedSubscriptions;
  final List<SkarbOnetimePurchaseIOS> onetimePurchases;

  SkarbPurchaseInfoIOS({
    required this.environment,
    required this.purchasedSubscriptions,
    required this.onetimePurchases,
  });
  static SkarbPurchaseInfoIOS fromJson(Map<String, dynamic> json) {
    return SkarbPurchaseInfoIOS(
      environment: json['environment'] as String,
      purchasedSubscriptions: (json['purchasedSubscriptions'] as List<dynamic>)
          .map((e) => SkarbPurchasedSubscriptionIOS.fromJson(
              Map<String, dynamic>.from(e)))
          .toList(),
      onetimePurchases: (json['onetimePurchases'] as List<dynamic>)
          .map((e) =>
              SkarbOnetimePurchaseIOS.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SkarbPurchasedSubscriptionIOS {
  final String transactionID;
  final String originalTransactionID;
  final DateTime expiryDate;
  final String productID;
  final int quantity;
  final bool introOfferPeriod;
  final bool trialPeriod;
  final String renewalInfo;

  SkarbPurchasedSubscriptionIOS({
    required this.transactionID,
    required this.originalTransactionID,
    required this.expiryDate,
    required this.productID,
    required this.quantity,
    required this.introOfferPeriod,
    required this.trialPeriod,
    required this.renewalInfo,
  });

  static SkarbPurchasedSubscriptionIOS fromJson(Map<String, dynamic> json) {
    return SkarbPurchasedSubscriptionIOS(
      transactionID: json['transactionID'] as String,
      originalTransactionID: json['originalTransactionID'] as String,
      expiryDate: DateTime.fromMillisecondsSinceEpoch(
          ((json['expiryDate'] as double) * 1000).toInt()),
      productID: json['productID'] as String,
      quantity: json['quantity'] as int,
      introOfferPeriod: json['introOfferPeriod'] as bool,
      trialPeriod: json['trialPeriod'] as bool,
      renewalInfo: json['renewalInfo'] as String,
    );
  }
}

class SkarbOnetimePurchaseIOS {
  final String transactionID;
  final DateTime purchaseDate;
  final String productID;
  final int quantity;

  SkarbOnetimePurchaseIOS({
    required this.transactionID,
    required this.purchaseDate,
    required this.productID,
    required this.quantity,
  });

  static SkarbOnetimePurchaseIOS fromJson(Map<String, dynamic> json) {
    return SkarbOnetimePurchaseIOS(
      transactionID: json['transactionID'] as String,
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(
          ((json['purchaseDate'] as double) * 1000).toInt()),
      productID: json['productID'] as String,
      quantity: json['quantity'] as int,
    );
  }
}
