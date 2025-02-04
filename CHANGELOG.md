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