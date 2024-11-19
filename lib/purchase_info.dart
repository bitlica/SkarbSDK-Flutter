class SkarbPurchaseInfo {
  final String environment;
  final List<SkarbPurchasedSubscription> purchasedSubscriptions;
  final List<SkarbOnetimePurchase> onetimePurchases;

  SkarbPurchaseInfo({
    required this.environment,
    required this.purchasedSubscriptions,
    required this.onetimePurchases,
  });

  static SkarbPurchaseInfo fromJson(Map<String, dynamic> json) {
    return SkarbPurchaseInfo(
      environment: json['environment'] as String,
      purchasedSubscriptions: (json['purchasedSubscriptions'] as List<dynamic>)
          .map((e) =>
              SkarbPurchasedSubscription.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      onetimePurchases: (json['onetimePurchases'] as List<dynamic>)
          .map((e) =>
              SkarbOnetimePurchase.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class SkarbPurchasedSubscription {
  final String transactionID;
  final String originalTransactionID;
  final DateTime expiryDate;
  final String productID;
  final int quantity;
  final bool introOfferPeriod;
  final bool trialPeriod;
  final String renewalInfo;

  SkarbPurchasedSubscription({
    required this.transactionID,
    required this.originalTransactionID,
    required this.expiryDate,
    required this.productID,
    required this.quantity,
    required this.introOfferPeriod,
    required this.trialPeriod,
    required this.renewalInfo,
  });

  static SkarbPurchasedSubscription fromJson(Map<String, dynamic> json) {
    return SkarbPurchasedSubscription(
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

class SkarbOnetimePurchase {
  final String transactionID;
  final DateTime purchaseDate;
  final String productID;
  final int quantity;
  final String? purchaseToken;

  SkarbOnetimePurchase({
    required this.transactionID,
    required this.purchaseDate,
    required this.productID,
    required this.quantity,
    this.purchaseToken,
  });

  static SkarbOnetimePurchase fromJson(Map<String, dynamic> json) {
    return SkarbOnetimePurchase(
      transactionID: json['transactionID'] as String,
      purchaseDate: DateTime.fromMillisecondsSinceEpoch(
          ((json['purchaseDate'] as double) * 1000).toInt()),
      productID: json['productID'] as String,
      purchaseToken: json['purchaseToken'] as String?,
      quantity: json['quantity'] as int,
    );
  }
}
