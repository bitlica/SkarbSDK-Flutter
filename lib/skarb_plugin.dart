import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_keychain/flutter_keychain.dart';
import 'package:intl/intl.dart';
import 'package:purchases_flutter/purchases_flutter.dart' as rc;
import 'package:skarb_plugin/country_codes.dart';
import 'package:skarb_plugin/purchase_info.dart';
import 'package:skarb_plugin/purchase_result.dart';
import 'package:skarb_plugin/skarb_exception.dart';
import 'package:skarb_plugin/skarb_logger.dart';
import 'package:skarb_plugin/skarb_offerings.dart';
import 'package:skarb_plugin/skarb_transaction.dart';

class SkarbPlugin {
  static const MethodChannel _channel = MethodChannel('skarb_plugin');

  static SKOfferings? offerings;
  static SkarbLogger? logger;

  static String? _androidOfferingId;
  static String? _androidCountryCode;
  static String? _lifetimePurchaseIdentifier;

  static const String _purchasedRevenueCatPackagesKeychainKey =
      'skarb_purchasedRevenueCatPackages';
  static const String _isNotFirstInstallKeychainKey = 'skarb_isNotFirstInstall';
  static bool _shouldListenToRevenueCatTransactionsChanges = false;

  static Function(SkarbTransaction)? _onPendingTransactionCompleted;

  static Future<String?> getReceiptBase64() async {
    if (Platform.isAndroid) {
      return null;
    }
    return await _channel.invokeMethod('getReceiptBase64');
  }

  static Future<String?> getSkarbDeviceId() async {
    if (Platform.isAndroid) {
      return null;
    }
    return await _channel.invokeMethod('getSkarbDeviceId');
  }

  static Future<void> initialize({
    required String? deviceId,
    required String revenueCatGoogleKey,
    Function(SkarbTransaction)? onPendingTransactionCompleted,
    String? androidOfferingId,
    String? lifetimePurchaseIdentifier,
  }) async {
    _androidOfferingId = androidOfferingId;
    _onPendingTransactionCompleted = onPendingTransactionCompleted;
    _lifetimePurchaseIdentifier = lifetimePurchaseIdentifier;
    logger?.logEvent(
      eventType: SkarbEventType.info,
      message: 'initialize',
    );
    if (Platform.isAndroid) {
      await rc.Purchases.setLogLevel(rc.LogLevel.debug);
      await rc.Purchases.setLogHandler((logLevel, message) {
        // This is a workaround for the issue with the country code not being
        // available in the Purchases SDK.
        // The log message format may change in the future.
        if (message.startsWith('Billing connected with country code: ')) {
          final twoLetterCode = message.substring(37);
          _androidCountryCode = countryCodes[twoLetterCode];
        }
        logger?.logEvent(
          eventType: SkarbEventType.verbose,
          message: 'Purchases log: $message',
        );
      });

      rc.PurchasesConfiguration configuration;
      configuration = rc.PurchasesConfiguration(revenueCatGoogleKey);
      configuration.appUserID = deviceId;
      await rc.Purchases.configure(configuration);

      await _channel.invokeMethod('initialize', {
        'deviceId': deviceId,
        'clientKey': 'aifriendandroid',
      });
    } else if (Platform.isIOS) {
      await _channel.invokeMethod('initialize', {
        'deviceId': deviceId,
        'lifetimePurchaseIdentifier': lifetimePurchaseIdentifier,
      });
    }
    logger?.logEvent(
      eventType: SkarbEventType.info,
      message: 'initialize success',
    );
  }

  static Future<String?> getCountryCode() async {
    if (Platform.isIOS) {
      return await _channel.invokeMethod('getCountryCode');
    } else if (Platform.isAndroid) {
      return _androidCountryCode;
    }
    return null;
  }

  static Future<String?> sendAFSource(
      Map<dynamic, dynamic> conversionInfo, String? uid) async {
    Map<String, dynamic> info = {};

    conversionInfo.forEach((key, value) {
      if (key is String) {
        info[key] = value;
      }
    });

    if (Platform.isAndroid) {
      await _channel.invokeMethod('sendSource', {'features': info, 'uid': uid});
      return _channel.invokeMethod('getDeviceId');
    }

    return await _channel
        .invokeMethod('sendAFSource', {'conversionInfo': info, 'uid': uid});
  }

  static Future<String?> sendTest(String? name, String? group) async {
    if (Platform.isAndroid) {
      await _channel.invokeMethod('sendTest', {'name': name, 'group': group});
      return '';
    }
    return await _channel
        .invokeMethod('sendTest', {'name': name, 'group': group});
  }

  static Future<void> setRevenueCatUserId(String userId) async {
    if (Platform.isAndroid) {
      await rc.Purchases.logIn(userId);
    }
  }

  static Future<String?> getRevenueCatUserId() async {
    if (Platform.isAndroid) {
      return await rc.Purchases.appUserID;
    }
    return null;
  }

  static Future<bool> isPremium() async {
    if (Platform.isAndroid) {
      try {
        rc.CustomerInfo customerInfo = await rc.Purchases.getCustomerInfo();
        logger?.logEvent(
          eventType: SkarbEventType.info,
          message: 'Obtained entitlements: ${customerInfo.entitlements.all}',
        );
        if (_lifetimePurchaseIdentifier != null) {
          final isLifetime = customerInfo.allPurchasedProductIdentifiers
              .contains(_lifetimePurchaseIdentifier);
          if (isLifetime) {
            return true;
          }
        }
        var isPro =
            customerInfo.entitlements.all['Unlimited Access']?.isActive ??
                false;
        if (isPro) {
          return true;
        }
      } on PlatformException catch (e) {
        logger?.logEvent(eventType: SkarbEventType.error, message: e.message);
      }
      return false;
    } else if (Platform.isIOS) {
      final result = await _channel.invokeMethod('isPremium');
      logger?.logEvent(
        eventType: SkarbEventType.info,
        message: 'isPremium success: ${result == true}',
      );
      return result == true;
    }
    return false;
  }

  /// Method may throw a SkarbException
  static Future<SkarbPurchaseInfo?> fetchUserPurchasesInfo() async {
    logger?.logEvent(
      eventType: SkarbEventType.info,
      message: 'fetchUserPurchasesInfo',
    );

    if (Platform.isAndroid) {
      final customerInfo = await rc.Purchases.getCustomerInfo();
      _completePendingRevenueCatTransactions(customerInfo);
      logger?.logEvent(
        eventType: SkarbEventType.info,
        message: 'fetchUserPurchasesInfo success',
      );
      if (_shouldListenToRevenueCatTransactionsChanges) {
        Future.delayed(const Duration(seconds: 10), () async {
          await rc.Purchases.syncPurchases();
          fetchUserPurchasesInfo();
        });
      }
      return SkarbPurchaseInfoAndroid();
    } else if (Platform.isIOS) {
      final result = await _channel.invokeMethod('fetchUserPurchasesInfo');
      if (result is String) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'fetchUserPurchasesInfo error $result',
        );
        throw SkarbException(result, 'FETCH_PURCHASE_ERROR');
      } else {
        logger?.logEvent(
          eventType: SkarbEventType.info,
          message: 'fetchUserPurchasesInfo success',
        );
        try {
          return SkarbPurchaseInfoIOS.fromJson(
              Map<String, dynamic>.from(result));
        } catch (_) {
          throw SkarbException('result parsing error', 'PARSING_ERROR');
        }
      }
    } else {
      throw SkarbException(
        'Unsupported platform',
        'INTERNAL_UNSUPPORTED_ERROR',
      );
    }
  }

  static Future<void> loadOfferings() async {
    if (Platform.isAndroid) {
      try {
        rc.Offerings rcOfferings = await rc.Purchases.getOfferings();
        rc.Offering? rcOffering;
        if (_androidOfferingId != null) {
          rcOffering = rcOfferings.all[_androidOfferingId!];
        } else {
          rcOffering = rcOfferings.current;
        }
        if (rcOffering != null) {
          purchaseTypeFromRCPackage(rc.Package p0) {
            switch (p0.packageType) {
              case rc.PackageType.annual:
                return PurchaseType.yearly;
              case rc.PackageType.monthly:
                return PurchaseType.monthly;
              case rc.PackageType.weekly:
                return PurchaseType.weekly;
              case rc.PackageType.lifetime:
              case rc.PackageType.sixMonth:
              case rc.PackageType.threeMonth:
              case rc.PackageType.twoMonth:
                return PurchaseType.unknown;
              case rc.PackageType.custom:
              case rc.PackageType.unknown:
                final unit = p0.storeProduct.defaultOption?.billingPeriod?.unit;
                final periodValue =
                    p0.storeProduct.defaultOption?.billingPeriod?.value;
                if (unit == rc.PeriodUnit.week && periodValue == 1) {
                  return PurchaseType.weekly;
                } else if (unit == rc.PeriodUnit.month && periodValue == 1) {
                  return PurchaseType.monthly;
                } else if (unit == rc.PeriodUnit.year && periodValue == 1) {
                  return PurchaseType.yearly;
                }
                return PurchaseType.consumable;
            }
          }

          weeklyPriceFromRCPackage(rc.Package p0) {
            switch (p0.packageType) {
              case rc.PackageType.annual:
                return _priceString(
                  p0.storeProduct.price / 52,
                  p0.storeProduct.currencyCode,
                );
              case rc.PackageType.monthly:
                return _priceString(
                  p0.storeProduct.price / 4,
                  p0.storeProduct.currencyCode,
                );
              default:
                return null;
            }
          }

          final packages = rcOffering.availablePackages
              .map(
                (e) => SKOfferPackage(
                  id: e.storeProduct.identifier,
                  description: e.storeProduct.description,
                  productId: e.storeProduct.defaultOption?.productId ??
                      e.storeProduct.identifier,
                  purchaseType: purchaseTypeFromRCPackage(e),
                  priceString: _priceString(
                    e.storeProduct.price,
                    e.storeProduct.currencyCode,
                  ),
                  weeklyPriceString: weeklyPriceFromRCPackage(e),
                  isTrial: e.storeProduct.defaultOption?.freePhase != null ||
                      e.storeProduct.defaultOption?.introPhase != null,
                ),
              )
              .toList();
          offerings = SKOfferings(
            offerings: [
              SKOffering(
                id: rcOffering.identifier,
                description: rcOffering.serverDescription,
                packages: packages,
              ),
            ],
          );
          logger?.logEvent(
            eventType: SkarbEventType.info,
            message:
                'loadOfferings: Obtained packages: ${packages.map((e) => e.id).join(',')}',
          );
        } else {
          logger?.logEvent(
            eventType: SkarbEventType.info,
            message: 'loadOfferings: Obtained no offerings',
          );
        }
      } on PlatformException catch (e) {
        if (e.code == "PurchasesErrorCode.purchaseCancelledError") {
          // optional error handling
        } else {
          logger?.logEvent(
            eventType: SkarbEventType.error,
            message: 'loadOfferings: error: ${e.message}',
          );
        }
      }
    } else if (Platform.isIOS) {
      final result = await _channel.invokeMethod('loadOfferings');
      if (result is String) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'loadOfferings error $result',
        );
      } else if (result != null) {
        offerings = SKOfferings.fromJson(Map<String, dynamic>.from(result));
      }
    }
  }

  static Future<void> restorePurchases() async {
    logger?.logEvent(
      eventType: SkarbEventType.info,
      message: 'restorePurchases',
    );
    if (Platform.isAndroid) {
      try {
        await rc.Purchases.restorePurchases();
        await _channel.invokeMethod('syncPurchases');
      } on PlatformException catch (e) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'restorePurchases error ${e.message}',
        );
      }
    } else if (Platform.isIOS) {
      final result = await _channel.invokeMethod('restorePurchases');
      if (result is String) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'restorePurchases error $result',
        );
      } else {
        logger?.logEvent(
          eventType: SkarbEventType.info,
          message: 'restorePurchases success',
        );
      }
    }
  }

  /// Method may throw a SkarbException
  /// Throws PaymentPendingException when payment is pending
  /// For pending purchases, the app should watch for the payment status change
  ///
  /// returns false when purchase is cancelled
  static Future<SkarbPurchaseResult> purchasePackage(String packageName) async {
    logger?.logEvent(
      eventType: SkarbEventType.info,
      message: "purchase $packageName",
    );
    if (Platform.isAndroid) {
      final rc.Offerings offerings = await rc.Purchases.getOfferings();
      rc.Offering? rcOffering;
      if (_androidOfferingId != null) {
        rcOffering = offerings.all[_androidOfferingId!];
      } else {
        rcOffering = offerings.current;
      }
      final package = rcOffering?.availablePackages.firstWhereOrNull(
          (element) =>
              (element.storeProduct.defaultOption?.productId ??
                  element.storeProduct.identifier) ==
              packageName);
      if (package == null) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'purchase $packageName PACKAGE_NOT_FOUND',
        );
        throw SkarbException(
          'Package not found',
          'PACKAGE_NOT_FOUND',
        );
      }
      try {
        final customerInfo = await rc.Purchases.purchasePackage(package);
        try {
          final purchasedTransaction = customerInfo.nonSubscriptionTransactions
              .lastWhere((element) => element.productIdentifier == packageName);
          final purchasedTransactions = await FlutterKeychain.get(
                  key: _purchasedRevenueCatPackagesKeychainKey)
              .then((value) => value != null ? value.split(';') : []);
          purchasedTransactions.add(purchasedTransaction.transactionIdentifier);
          await FlutterKeychain.put(
            key: _purchasedRevenueCatPackagesKeychainKey,
            value: purchasedTransactions.join(';'),
          );
        } catch (_) {}
        _completePendingRevenueCatTransactions(customerInfo);
        await _channel.invokeMethod('syncPurchases');
      } on PlatformException catch (e) {
        final code = rc.PurchasesErrorHelper.getErrorCode(e);
        if (code == rc.PurchasesErrorCode.purchaseCancelledError) {
          logger?.logEvent(
            eventType: SkarbEventType.info,
            message: 'purchase $packageName cancelled',
          );
          return SkarbPurchaseResultCancelled();
        }
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'purchase $packageName error ${e.toString()}',
        );
        if (code == rc.PurchasesErrorCode.paymentPendingError) {
          _shouldListenToRevenueCatTransactionsChanges = true;
          fetchUserPurchasesInfo();
          throw SkarbPaymentPendingException();
        }
        throw SkarbException(
          e.toString(),
          'PURCHASE_ERROR',
        );
      }
      return SkarbPurchaseResultSuccess(SkarbPurchaseInfoAndroid());
    } else if (Platform.isIOS) {
      final result =
          await _channel.invokeMethod('purchasePackage', {'name': packageName});
      if (result is Map<dynamic, dynamic>) {
        if (result['errorCode'] != null) {
          SkarbException exception = SkarbException.fromJson(result);
          if (exception.code == 'PAYMENT_CANCELLED') {
            return SkarbPurchaseResultCancelled();
          }
          logger?.logEvent(
            eventType: SkarbEventType.error,
            message: '${exception.code}: ${exception.message}',
          );
          throw exception;
        } else {
          try {
            return SkarbPurchaseResultSuccess(
              SkarbPurchaseInfoIOS.fromJson(Map<String, dynamic>.from(result)),
            );
          } catch (_) {
            throw SkarbException('result parsing error', 'PARSING_ERROR');
          }
        }
      } else {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'Unknown error',
        );
        throw SkarbException('Return type mismatch', 'INTERNAL_TYPE_ERROR');
      }
    } else {
      throw SkarbException(
        'Unsupported platform',
        'INTERNAL_UNSUPPORTED_ERROR',
      );
    }
  }

  static String _priceString(double price, String currencyCode) {
    final formatCurrency =
        NumberFormat.simpleCurrency(locale: 'en_US', name: currencyCode);
    return formatCurrency.format(price);
  }

  static Future<void> _completePendingRevenueCatTransactions(
      rc.CustomerInfo customerInfo) async {
    var purchasedTransactions =
        await FlutterKeychain.get(key: _purchasedRevenueCatPackagesKeychainKey)
            .then((value) => value != null ? value.split(';') : []);
    final isFirstInstall =
        await FlutterKeychain.get(key: _isNotFirstInstallKeychainKey)
            .then((value) => value != 'true');
    if (isFirstInstall) {
      await FlutterKeychain.put(
        key: _isNotFirstInstallKeychainKey,
        value: 'true',
      );
    }
    for (var transaction in customerInfo.nonSubscriptionTransactions) {
      if (purchasedTransactions.contains(transaction.transactionIdentifier)) {
        continue;
      }
      if (isFirstInstall) {
        purchasedTransactions.add(transaction.transactionIdentifier);
        continue;
      }
      final skarbTransaction = SkarbTransaction(
        transactionIdentifier: transaction.transactionIdentifier,
        productIdentifier: transaction.productIdentifier,
        purchaseDate: transaction.purchaseDate,
      );
      if (_onPendingTransactionCompleted != null) {
        _onPendingTransactionCompleted!(skarbTransaction);
      }
      purchasedTransactions.add(transaction.transactionIdentifier);
      _shouldListenToRevenueCatTransactionsChanges = false;
    }
    await FlutterKeychain.put(
      key: _purchasedRevenueCatPackagesKeychainKey,
      value: purchasedTransactions.join(';'),
    );
  }
}
