import 'package:skarb_plugin/purchase_info.dart';
import 'package:skarb_plugin/skarb_transaction.dart';

abstract class SkarbPurchaseResult {}

class SkarbPurchaseResultSuccess extends SkarbPurchaseResult {
  final SkarbPurchaseInfo purchaseInfo;

  SkarbPurchaseResultSuccess(this.purchaseInfo);
}

class SkarbPurchaseResultCancelled extends SkarbPurchaseResult {}

class RestorePurchasesResult {
  final bool success;
  final String? errorMessage;
  final List<SkarbTransaction> products;

  RestorePurchasesResult({
    required this.success,
    this.errorMessage,
    required this.products,
  });
}
