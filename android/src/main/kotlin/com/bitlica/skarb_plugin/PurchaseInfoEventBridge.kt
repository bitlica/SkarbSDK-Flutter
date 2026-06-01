package com.bitlica.skarb_plugin

import android.os.Handler
import android.os.Looper
import com.bitlica.skarbsdk.SkarbSDK
import com.bitlica.skarbsdk.model.SKUserPurchaseInfo
import io.flutter.plugin.common.EventChannel

/**
 * Streams cached [SKUserPurchaseInfo] snapshots to Dart over the
 * `skarb_plugin/purchase_info` EventChannel. Android counterpart of the iOS
 * `PurchaseInfoEventBridge`.
 *
 * On listen it subscribes to [SkarbSDK.observeUserPurchaseInfoUpdates]; thanks to
 * the SDK's `replay = 1` flow the current cached snapshot (if any) is delivered
 * immediately, mirroring the iOS replay-on-listen behaviour. Subsequent updates
 * fire on every server-verified cache refresh — including purchases completed by
 * external means (restore, store-initiated, host PayFlow) while in observer mode.
 */
class PurchaseInfoEventBridge : EventChannel.StreamHandler {

    private val mainHandler = Handler(Looper.getMainLooper())
    private var eventSink: EventChannel.EventSink? = null
    private var subscribed = false

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        subscribeIfPossible()
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /**
     * Subscribes to the SDK's purchase-info stream. Safe to call before
     * `SkarbSDK.initialize()` — it then no-ops and is retried by [SkarbPlugin]
     * right after initialize lands (mirrors the iOS `attach(manager:)` flow).
     *
     * Dart often subscribes during DI setup, before the plugin's `initialize`
     * MethodCall arrives; without this retry the collector would never register
     * and emits (`tryEmit`) would land in the replay buffer with no consumer.
     *
     * The subscriber relies on the SDK flow's `replay = 1`, so once attached it
     * immediately receives the latest cached snapshot, if any.
     */
    fun subscribeIfPossible() {
        if (subscribed) return
        // A failure here means SkarbSDK isn't initialized yet; it's intentionally
        // swallowed — SkarbPlugin calls this again right after initialize().
        runCatching {
            SkarbSDK.observeUserPurchaseInfoUpdates { info ->
                mainHandler.post { eventSink?.success(purchaseInfoToJson(info)) }
            }
        }.onSuccess {
            subscribed = true
        }
    }
}

/**
 * Wire JSON for [SKUserPurchaseInfo], shared by [SkarbPlugin] method results and
 * the [PurchaseInfoEventBridge] stream. Dates are encoded as epoch seconds
 * (Double), matching the Dart `SkarbPurchaseInfo.fromJson` contract and the iOS
 * payload.
 */
internal fun purchaseInfoToJson(purchaseInfo: SKUserPurchaseInfo): MutableMap<String, Any> {
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
