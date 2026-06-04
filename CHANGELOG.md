## 1.0.0

Release as a standalone library (with android analytics support).

## 1.0.1

Added getSkarbDeviceId method.

## 2.0.0

Added SkarbUserPurchaseInfo with info about the user's purchase history
Returning SkarbUserPurchaseInfo from fetchUserPurchasesInfo method
**fetchUserPurchasesInfo method may now throw an exception!**
Reworked purchasePackage return type

## 3.0.0

Removed RevenueCat dependency
Using full native Skarb SDK for handling purchases on Android

## 3.0.1

Fixed isPremium on Android

## 3.0.2

Fix: calling consumePurchase after a onetime purchase on Android

## 3.0.3

Updated Android SDK to 2.0.3 version with some fixes

## 3.0.4

Added androidClientKey to initialization

## 3.0.5

Added dailyPriceString calculation

## 3.2.0

Updated skarb to 2.0.6 version (added event channel to handle UnconsumedOneTimePurchases)

## 3.2.1

Updated skarb to 2.0.7 version (added getUnconsumedOneTimePurchases method)

## 3.2.4

Fixed crash on Android when calling getUnconsumedOneTimePurchases

## 3.3.0

Added onError function on loadOfferings function
Refactored SkarbPlugin.kt (clean up the code, removed getOrThrow)

## 3.3.1
Fixed Premium function call without internet

## 3.3.2
Updated `SkarbSDK-Android` to version 2.0.8 to resolve ANR issue during initialization.

## 3.3.3
Updated `SkarbSDK` to version `~> 0.6.22`

## 3.3.4
Updated `SkarbSDK` to version `~> 0.6.21`

## 3.3.5
Updated `SkarbSDK` to version `~> 0.6.23`

## 3.3.6
Added `monthlyPriceString` param 

## 3.3.7
Added `introductoryPriceString` param iOS only

## 3.3.8
Added `introductoryPriceString` param iOS/Android 

## 3.3.9
Removed `lifetimePurchaseIdentifier` param
Changed logic of isPremium for lifetime purchase

## 3.4.0
Updated `SkarbSDK` android to version `2.1.0`
Updated SKD version 34->35
Fixed `isPremium` returned result issues

## 3.4.1
Added performance measurement for methods

## 3.4.2
Added `isObservable` param for iOS `initialize`

## 3.4.3
Updated Skarb android to 2.2
added "isObservable" param in function SkarbSDK.initialize (android)

## 3.4.4

Added `RestorePurchasesResult` and improved `restorePurchases` to return error message and collected purchases.

## 3.4.5

Added error description on `restorePurchases`.

## 3.4.6
Updated Skarb android to 2.2.1
Updated `introductory_price_string` Android

## 3.4.7
Updated Skarb android to 2.2.2 (add Google Play in-app messaging for subscription payment recovery)

## 3.4.8
Updated Skarb android to 2.2.3 (Initialization changes)

## 3.6.0
iOS Swift Package Manager support (alongside CocoaPods):
- Added `ios/skarb_plugin/Package.swift` declaring the plugin as an SPM package. Depends on the native `SkarbSDK` iOS package from `github.com/bitlica/SkarbSDK-iOS` (from 0.6.31) — `grpc-swift` / `swift-nio` / `swift-nio-ssl` come transitively via SPM.
- Sources moved from `ios/Classes/` to `ios/skarb_plugin/Sources/skarb_plugin/` (Flutter SPM convention). Git history preserved via rename.
- `ios/skarb_plugin.podspec` `source_files` updated to the new path; `s.dependency 'SkarbSDK', '~> 0.6.30'` and the rest of the podspec unchanged — hosts that haven't enabled Flutter SPM mode continue to integrate via CocoaPods exactly as before.
- Hosts can opt into the SPM path with `flutter config --enable-swift-package-manager`. **Do not mix**: keeping `pod 'SkarbSDK'` in the host Podfile while also pulling the SPM package produces duplicate copies of `CNIOBoringSSL`/`SwiftNIO`/`gRPC` that crash at TLS context creation — drop the explicit pod from the Podfile when switching to SPM.

## 3.5.0
iOS purchase-info broadcast surface:
- Added `SkarbPlugin.onPurchaseInfoUpdated` — broadcast `Stream<SkarbPurchaseInfo?>` that emits whenever the native cache refreshes (after purchase/restore/receipt validation, or SDK-driven background re-validation). On subscribe replays the current cached snapshot. iOS only; Android emits empty stream.
- Added `SkarbPlugin.getCachedUserPurchasesInfo()` — synchronous-ish cache read, no network. iOS only.
- iOS: bumped SkarbSDK pin from `'0.6.23'` to `'~> 0.6.30'` (required for the new APIs and for downstream ScreenBuilder SDK consumers).
- iOS internal: notification name `SubscriptionValidWasUpdated` exposed as `BitlicaSkarbManagerImplementation.userPurchasesInfoDidUpdateNotification` (typed `Notification.Name`).

## 3.6.1
Android support for `onPurchaseInfoUpdated` (Android counterpart of the iOS 3.5.0 stream):
- `SkarbPlugin.onPurchaseInfoUpdated` now emits on Android too (previously an empty stream). Bridged over the `skarb_plugin/purchase_info` EventChannel from the native SkarbSDK's new `observeUserPurchaseInfoUpdates` API; the current cached snapshot replays on subscribe. The bridge defers and retries the subscription after `initialize`, so it works even when the host subscribes before init.
- Updated Skarb android to 2.2.4 (adds `observeUserPurchaseInfoUpdates` / `getCachedUserPurchaseInfoIfAvailable`; externally-completed purchases — restore / store-initiated / host PayFlow — refresh the cache when initialized with `isObservable: true`).

## 3.6.2
Added `setProfileId()` method to expose `setObfuscatedProfileId` from Android SDK
Updated Skarb android to 2.2.5