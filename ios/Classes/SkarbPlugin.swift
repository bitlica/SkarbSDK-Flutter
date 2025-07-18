import Flutter
import SkarbSDK
import StoreKit
import UIKit

public class SkarbPlugin: NSObject, FlutterPlugin {
    private var manager: BitlicaSkarbManager? = nil

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "skarb_plugin", binaryMessenger: registrar.messenger())
        let instance = SkarbPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "getCountryCode":
            if let storefront = SKPaymentQueue.default().storefront {
                result(storefront.countryCode)
            }
            result(nil)
        case "getReceiptBase64":
            getReceiptBase64(result: result)
        case "getSkarbDeviceId":
            result(getSkarbDeviceId())
        case "initialize":
            SkarbSDK.isLoggingEnabled = true
            var deviceId: String? = nil
            if let args = call.arguments as? [String: Any] {
                if let id = args["deviceId"] as? String {
                    deviceId = id
                }
            }
            manager = BitlicaSkarbManagerImplementation(
                clientId: "aifriend",
                isObservable: false,
                deviceId: deviceId,
            )
            manager?.delegate = self
            result(nil)
        case "fetchUserPurchasesInfo":
            manager?.fetchUserPurchasesInfo(with: .always) { fetchResult in
                switch fetchResult {
                case let .success(info):
                    result(info.toJson())
                case let .failure(error):
                    result(self.errorDescription(error))
                }
            }
        case "sendAFSource":
            if let args = call.arguments as? [String: Any], let conversionInfo = args["conversionInfo"] as? [String: Any], let uid = args["uid"] as? String {
                SkarbSDK.sendSource(broker: .appsflyer,
                                    features: conversionInfo,
                                    brokerUserID: uid)
                result(SkarbSDK.getDeviceId())
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments provided", details: nil))
            }
        case "sendTest":
            if let args = call.arguments as? [String: Any], let name = args["name"] as? String, let group = args["group"] as? String {
                SkarbSDK.sendTest(name: name,
                                  group: group)
                result(nil)
            } else {
                result(FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid arguments provided", details: nil))
            }
        case "isPremium":
            result(manager?.isPremium ?? false)
        case "restorePurchases":
            manager?.restorePurchases { [weak self] restoreResult in
                switch restoreResult {
                case .success:
                    result(nil)
                case let .failure(error):
                    result(self?.errorDescription(error))
                }
            }
        case "loadOfferings":
            manager?.requestOffering(with: .always) { [weak self] error in
                guard let self else {
                    result(nil)
                    return
                }
                if let error = error {
                    result(self.errorDescription(error))
                    return
                }
                let offerings = self.manager?.offerings?.toJson()
                result(offerings)
            }
        case "purchasePackage":
            guard let args = call.arguments as? [String: Any], let name = args["name"] as? String else {
                result([
                    "message": "incorrect args: \(call.arguments ?? "nil")",
                    "errorCode": "INCORRECT_ARGS",
                ])
                return
            }

            manager?.requestOffering(with: .always) { [weak self] _ in
                guard let self else {
                    result([
                        "message": "unknown error",
                        "errorCode": "UNKNOWN",
                    ])
                    return
                }
                guard let package = self.manager?.packages?.first(where: { package in
                    package.productId == name
                }) else {
                    result([
                        "message": "package \(name) not found",
                        "errorCode": "PACKAGE_NOT_FOUND",
                    ])
                    return
                }
                self.manager?.purchase(package: package,
                                       eventParams: [:])
                { [weak self] purchaseResult in
                    switch purchaseResult {
                    case let .success(info):
                        result(info.toJson())
                    case let .failure(error):
                        result([
                            "message": self?.errorDescription(error),
                            "errorCode": self?.errorCode(error),
                        ])
                    }
                }
            }

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func getReceiptBase64(result: @escaping FlutterResult) {
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: receiptURL.path)
        {
            do {
                let receiptData = try Data(contentsOf: receiptURL)
                let base64EncodedReceipt = receiptData.base64EncodedString()
                result(base64EncodedReceipt)
            } catch {
                result(nil)
            }
        } else {
            result(nil)
        }
    }

    private func getSkarbDeviceId() -> String {
        return SkarbSDK.getDeviceId()
    }

    private func errorDescription(_ error: Error) -> String {
        if let error = error as? SKError {
            return "SKError \(error.errorCode) \(error.localizedDescription) \(error.userInfo) \(error.errorUserInfo)"
        } else if let error = error as? SKResponseError {
            return "SKResponseError \(error.code) \(error.message)"
        } else {
            return error.localizedDescription
        }
    }

    private func errorCode(_ error: Error) -> String {
        if let error = error as? SKError {
            let code = SKError.Code(rawValue: error.errorCode)
            switch code {
            case .paymentCancelled:
                return "PAYMENT_CANCELLED"
            case .clientInvalid:
                return "CLIENT_INVALID"
            case .paymentNotAllowed:
                return "PAYMENT_NOT_ALLOWED"
            case .paymentInvalid:
                return "PAYMENT_INVALID"
            case .storeProductNotAvailable:
                return "STORE_PRODUCT_NOT_AVAILABLE"
            case .cloudServicePermissionDenied:
                return "CLOUD_SERVICE_PERMISSION_DENIED"
            case .cloudServiceNetworkConnectionFailed:
                return "CLOUD_SERVICE_NETWORK_CONNECTION_FAILED"
            default:
                return "STOREKIT_ERROR"
            }
        } else if let error = error as? SKResponseError {
            if error.code == SKResponseError.noResponseCode {
                return "SKARB_NO_RESPONSE"
            } else if [-1009, -1005, -1004, -1003, -1001].contains(error.code) {
                return "SKARB_NETWORK_ERROR"
            } else {
                return "SKARB_ERROR"
            }
        } else {
            return "UNKNOWN_GENERAL_ERROR"
        }
    }
}

extension SkarbPlugin: BitlicaSkarbManagerDelegate {
    public func storeKitUpdatedTransaction(_: SKPaymentTransaction) {}

    public func storeKit(shouldAddStorePayment _: SKPayment, for _: SKProduct) -> Bool {
        return false
    }
}
