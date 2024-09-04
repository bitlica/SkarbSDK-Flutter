import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:skarb_plugin/country_codes.dart';
import 'package:skarb_plugin/purchase_info.dart';
import 'package:skarb_plugin/purchase_result.dart';
import 'package:skarb_plugin/skarb_exception.dart';
import 'package:skarb_plugin/skarb_logger.dart';
import 'package:skarb_plugin/skarb_offerings.dart';

class SkarbPlugin {
  static const MethodChannel _channel = MethodChannel('skarb_plugin');

  static SKOfferings? offerings;
  static SkarbLogger? logger;

  static Future<String?> getReceiptBase64() async {
    if (Platform.isAndroid) {
      return null;
    }
    return await _channel.invokeMethod('getReceiptBase64');
  }

  static Future<String?> getSkarbDeviceId() async {
    if (Platform.isAndroid) {
      return _channel.invokeMethod('getDeviceId');
    }
    return _channel.invokeMethod('getSkarbDeviceId');
  }

  static Future<void> initialize({
    required String? deviceId,
    required String revenueCatGoogleKey,
    String? lifetimePurchaseIdentifier,
  }) async {
    logger?.logEvent(
      eventType: SkarbEventType.info,
      message: 'initialize',
    );
    if (Platform.isAndroid) {
      await _channel.invokeMethod('initialize', {
        'deviceId': deviceId,
        'lifetimePurchaseIdentifier': lifetimePurchaseIdentifier,
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
      try {
        final twoLetterCode = await _channel.invokeMethod('getRegionCode');
        return countryCodes[twoLetterCode];
      } catch (e) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'getCountryCode error: $e',
        );
        return null;
      }
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

  static Future<bool> isPremium() async {
    if (Platform.isAndroid) {
      final result = await _channel.invokeMethod('isPremium');
      logger?.logEvent(
        eventType: SkarbEventType.info,
        message: 'isPremium success: ${result == true}',
      );
      return result == true;
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
      try {
        final result = await _channel.invokeMethod('fetchUserPurchasesInfo');
        logger?.logEvent(
          eventType: SkarbEventType.info,
          message: 'fetchUserPurchasesInfo success',
        );
        return SkarbPurchaseInfo.fromJson(Map<String, dynamic>.from(result));
      } catch (err) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'fetchUserPurchasesInfo error $err',
        );
        throw SkarbException(err.toString(), 'FETCH_PURCHASE_ERROR');
      }
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
          return SkarbPurchaseInfo.fromJson(Map<String, dynamic>.from(result));
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
        final result = await _channel.invokeMethod('loadOfferings');
        offerings = SKOfferings.fromJson(Map<String, dynamic>.from(result));
        logger?.logEvent(
          eventType: SkarbEventType.info,
          message: 'loadOfferings: success ${result.toString()}',
        );
      } on PlatformException catch (e) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'loadOfferings error ${e.message}',
        );
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
      // await rc.Purchases.restorePurchases();
      await fetchUserPurchasesInfo();
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
  static Future<SkarbPurchaseResult> purchasePackage(String packageName) async {
    logger?.logEvent(
      eventType: SkarbEventType.info,
      message: "purchase $packageName",
    );
    if (Platform.isAndroid) {
      try {
        final result = await _channel
            .invokeMethod('purchasePackage', {'name': packageName});
        return SkarbPurchaseResultSuccess(
            SkarbPurchaseInfo.fromJson(Map<String, dynamic>.from(result)));
      } on PlatformException catch (e) {
        logger?.logEvent(
          eventType: SkarbEventType.error,
          message: 'purchase $packageName error ${e.toString()}',
        );
        if (e.message?.contains('CanceledByUser') ?? false) {
          return SkarbPurchaseResultCancelled();
        }
        throw SkarbException(
          e.toString(),
          'PURCHASE_ERROR',
        );
      }
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
              SkarbPurchaseInfo.fromJson(Map<String, dynamic>.from(result)),
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
}
