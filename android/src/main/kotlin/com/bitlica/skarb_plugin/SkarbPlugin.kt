package com.bitlica.skarb_plugin

import android.app.Activity
import android.app.Application
import com.bitlica.skarbsdk.SkarbSDK
import com.bitlica.skarbsdk.model.SKBroker
import com.bitlica.skarbsdk.model.SKOfferPackage
import com.bitlica.skarbsdk.model.SKOfferings
import com.bitlica.skarbsdk.model.SKRefreshPolicy
import com.bitlica.skarbsdk.model.SKUserPurchaseInfo
import com.bitlica.skarbsdk.model.SKOneTimePurchase
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.text.NumberFormat
import java.util.Currency

/** SkarbPlugin */
class SkarbPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var methodChannel: MethodChannel

    private var lifetimePurchaseIdentifier: String? = null

    private lateinit var application: Application
    private var activity: Activity? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {

        val tag = "onAttachedToEngine"
        var context = flutterPluginBinding.applicationContext
        while (context != null) {
            application = context as Application
            if (application != null) {
                break
            } else {
                context = context.applicationContext
            }
        }

        methodChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "skarb_plugin")
        methodChannel.setMethodCallHandler(this)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onDetachedFromActivity() {}

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method == "initialize") {
            val clientKey = call.argument<String>("clientKey")
            val deviceId = call.argument<String>("deviceId")
            val amplitudeApiKey = call.argument<String>("amplitude_api_key")
            lifetimePurchaseIdentifier = call.argument<String>("lifetimePurchaseIdentifier")
            SkarbSDK.isLoggingEnabled = true
            SkarbSDK.initialize(application, clientKey!!, deviceId, amplitudeApiKey)
            result.success(null)
        } else if (call.method == "getDeviceId") {
            val deviceId = SkarbSDK.getDeviceId()
            result.success(deviceId)
        } else if (call.method == "sendTest") {
            val name = call.argument<String>("name")
            val group = call.argument<String>("group")
            SkarbSDK.sendTest(name!!, group!!)
            result.success(null)
        } else if (call.method == "sendGAID") {
            val id = call.argument<String>("id")
            SkarbSDK.sendGAID(id!!)
            result.success(null)
        } else if (call.method == "sendSource") {
            val broker = SKBroker.Appsflyer
            val features = call.argument<Map<String, Any>>("features")
            val brokerUserID = call.argument<String>("uid")
            SkarbSDK.sendSource(broker, features!!, brokerUserID)
            result.success(null)
        } else if (call.method == "syncPurchases") {
            SkarbSDK.syncPurchases()
            result.success(null)
        } else if (call.method == "loadOfferings") {
            SkarbSDK.getOfferings(SKRefreshPolicy.Always) { offeringsResult ->
                try {
                    val offerings = offeringsResult.getOrThrow()
                    val json = skOfferingsToJson(offerings)
                    result.success(json)
                } catch (e: Exception) {
                    result.error(
                        "Error",
                        e.message,
                        null
                    )
                }
            }
        } else if (call.method == "purchasePackage") {
            val packageId = call.argument<String>("name")
            SkarbSDK.getOfferings(SKRefreshPolicy.MemoryCached) { offeringsResult ->
                try {
                    val offerings = offeringsResult.getOrThrow()
                    val offering =
                        offerings.allOfferingPackages.firstOrNull { it.productId == packageId }
                            ?: throw Exception("Package not found")
                    val activityInstance = activity ?: throw Exception("Activity not found")
                    SkarbSDK.purchasePackage(activityInstance, offering) { purchaseResult ->
                        try {
                            val purchase = purchaseResult.getOrThrow()
                            val json = purchaseInfoToJson(purchase)
                            if (offering.purchaseType == com.bitlica.skarbsdk.model.PurchaseType.Consumable) {
                                val token =
                                    purchase.oneTimePurchases.filter { it.productId == packageId }
                                        .maxBy { it.purchaseDate }.purchaseToken
                                if (token != null) {
                                    SkarbSDK.consumePurchase(token)
                                    json["isConsumed"] = true
                                }
                            }
                            result.success(json)
                        } catch (e: Exception) {
                            result.error(
                                "Error",
                                e.message,
                                null
                            )
                        }
                    }
                } catch (e: Exception) {
                    result.error(
                        "Error",
                        e.message,
                        null
                    )
                }
            }
        } else if (call.method == "fetchUserPurchasesInfo") {
            SkarbSDK.verifyPurchase(SKRefreshPolicy.Always) { purchasesResult ->
                try {
                    val purchases = purchasesResult.getOrThrow()
                    val json = purchaseInfoToJson(purchases)
                    result.success(json)
                } catch (e: Exception) {
                    result.error(
                        "Error",
                        e.message,
                        null
                    )
                }
            }
        } else if (call.method == "isPremium") {
            SkarbSDK.verifyPurchase(SKRefreshPolicy.Always) { purchasesResult ->
                try {
                    val purchases = purchasesResult.getOrThrow()
                    val lifetime = purchases.oneTimePurchases.firstOrNull {
                        it.productId == lifetimePurchaseIdentifier
                    }
                    val subscription = purchases.purchasedSubscriptions.firstOrNull {
                        it.isActive
                    }
                    result.success(lifetime != null || subscription != null)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
        } else if (call.method == "getRegionCode") {
            val regionCode = SkarbSDK.getRegionCode() {
                try {
                    val code = it.getOrThrow()
                    result.success(code)
                } catch (e: Exception) {
                    result.error(
                        "Error",
                        e.message,
                        null
                    )
                }
            }
        } else if (call.method == "consumePurchase") {
            try {
                val purchaseToken = call.argument<String>("purchaseToken")
                if (purchaseToken != null) {
                    SkarbSDK.consumePurchase(purchaseToken)
                    result.success(true)
                    return
                }
                result.success(false)
            } catch (e: Exception) {
                result.success(false)
            }
        } else if (call.method == "getUnconsumedOneTimePurchases") {
            try {
                SkarbSDK.getUnconsumedOneTimePurchases() { unconsumedOneTimePurchases ->
                    val unconsumedOneTimePurchasesResult = unconsumedOneTimePurchases.getOrThrow()
                    val json =
                        unconsumedOneTimePurchasesResultToJson(unconsumedOneTimePurchasesResult);
                    result.success(json)
                }
            } catch (e: Exception) {
                result.error(
                    "Error",
                    e.message,
                    null
                )
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
    }

    private fun skOfferingsToJson(offerings: SKOfferings): Map<String, Any> {
        return mapOf(
            "offerings" to offerings.offerings.map { offering ->
                mapOf(
                    "id" to offering.id,
                    "description" to offering.description,
                    "packages" to offering.packages.map { skOfferPackage ->
                        mapOf(
                            "id" to skOfferPackage.id,
                            "description" to skOfferPackage.description,
                            "product_id" to skOfferPackage.productId,
                            "purchase_type" to purchaseTypeToString(skOfferPackage.purchaseType),
                            "price_string" to formatPrice(
                                skOfferPackage.storeProduct.priceAsDouble,
                                skOfferPackage.storeProduct.currency
                            ),
                            "weekly_price_string" to weeklyPrice(skOfferPackage),
                            "daily_price_string" to dailyPrice(skOfferPackage),
                            // TODO: Determine if this is a trial
                            "is_trial" to skOfferPackage.storeProduct.hasTrial,
                        )
                    }
                )
            }
        )
    }

    private fun purchaseTypeToString(purchaseType: com.bitlica.skarbsdk.model.PurchaseType): String {
        return when (purchaseType) {
            com.bitlica.skarbsdk.model.PurchaseType.Weekly -> "weekly"
            com.bitlica.skarbsdk.model.PurchaseType.Monthly -> "monthly"
            com.bitlica.skarbsdk.model.PurchaseType.Yearly -> "yearly"
            com.bitlica.skarbsdk.model.PurchaseType.Consumable -> "consumable"
            com.bitlica.skarbsdk.model.PurchaseType.NonConsumable -> "non_consumable"
            com.bitlica.skarbsdk.model.PurchaseType.Unknown -> "unknown"
        }
    }

    private fun formatPrice(price: Double, currency: String): String {
        val numberFormat = NumberFormat.getCurrencyInstance()
        numberFormat.currency = Currency.getInstance(currency)
        return numberFormat.format(price)
    }

    private fun weeklyPrice(offerPackage: SKOfferPackage): String {
        val totalPrice = offerPackage.storeProduct.priceAsDouble
        val weeklyPrice = when (offerPackage.purchaseType) {
            com.bitlica.skarbsdk.model.PurchaseType.Weekly -> totalPrice
            com.bitlica.skarbsdk.model.PurchaseType.Monthly -> totalPrice / 4
            com.bitlica.skarbsdk.model.PurchaseType.Yearly -> totalPrice / 52
            else -> totalPrice
        }
        val currency = offerPackage.storeProduct.currency
        return formatPrice(weeklyPrice, currency)
    }

    private fun dailyPrice(offerPackage: SKOfferPackage): String {
        val totalPrice = offerPackage.storeProduct.priceAsDouble
        val weeklyPrice = when (offerPackage.purchaseType) {
            com.bitlica.skarbsdk.model.PurchaseType.Weekly -> totalPrice / 7
            com.bitlica.skarbsdk.model.PurchaseType.Monthly -> totalPrice / 30
            com.bitlica.skarbsdk.model.PurchaseType.Yearly -> totalPrice / 365
            else -> totalPrice
        }
        val currency = offerPackage.storeProduct.currency
        return formatPrice(weeklyPrice, currency)
    }

    private fun purchaseInfoToJson(purchaseInfo: SKUserPurchaseInfo): MutableMap<String, Any> {
        return mutableMapOf(
            "environment" to purchaseInfo.environment,
            "purchasedSubscriptions" to purchaseInfo.purchasedSubscriptions.map { subscription ->
                mapOf(
                    "transactionID" to subscription.transactionId,
                    "originalTransactionID" to subscription.originalTransactionId,
                    "expiryDate" to subscription.expiryDate.time.toDouble() / 1000,
                    "productID" to subscription.productId,
                    "quantity" to subscription.quantity,
                    "introOfferPeriod" to subscription.introOfferPeriod,
                    "trialPeriod" to subscription.trialPeriod,
                    "renewalInfo" to subscription.renewalInfo,
                )
            },
            "onetimePurchases" to purchaseInfo.oneTimePurchases.map { purchase ->
                mapOf(
                    "transactionID" to purchase.transactionId,
                    "purchaseDate" to purchase.purchaseDate.time.toDouble() / 1000,
                    "productID" to purchase.productId,
                    "quantity" to purchase.quantity,
                )
            }
        )
    }

    private fun unconsumedOneTimePurchasesResultToJson(unconsumedOneTimePurchases: List<SKOneTimePurchase>): Map<String, Any> {
        return mapOf(
            "onetimePurchases" to unconsumedOneTimePurchases.map { purchase ->
                mapOf(
                    "transactionID" to purchase.transactionId,
                    "purchaseDate" to purchase.purchaseDate.time.toDouble() / 1000,
                    "productID" to purchase.productId,
                    "quantity" to purchase.quantity,
                    "purchaseToken" to purchase.purchaseToken,
                )
            }
        )
    }
}
