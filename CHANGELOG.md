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
