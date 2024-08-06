import 'package:skarb_plugin/purchase_info.dart';

abstract class SkarbPurchaseResult {}

class SkarbPurchaseResultSuccess extends SkarbPurchaseResult {
  final SkarbPurchaseInfo purchaseInfo;

  SkarbPurchaseResultSuccess(this.purchaseInfo);
}

class SkarbPurchaseResultCancelled extends SkarbPurchaseResult {}
