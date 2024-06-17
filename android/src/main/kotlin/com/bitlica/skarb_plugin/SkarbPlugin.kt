package com.bitlica.skarb_plugin

import androidx.annotation.NonNull
import com.bitlica.skarbsdk.SkarbSDK
import com.bitlica.skarbsdk.model.SKBroker
import android.app.Application

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/** SkarbPlugin */
class SkarbPlugin: FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private lateinit var channel : MethodChannel

  private lateinit var application: Application

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {

    val tag = "onAttachedToEngine"
    var context = flutterPluginBinding.applicationContext
    while (context != null) {
        //  Log.w(tag, "Trying to resolve Application from Context: ${context.javaClass.name}")
        application = context as Application
        if (application != null) {
            // Log.i(tag, "Resolved Application from Context")
            break
        } else {
            context = context.applicationContext
        }
    }
    if (application == null) {
        // Log.e(tag, "Fail to resolve Application from Context")
    }

    channel = MethodChannel(flutterPluginBinding.binaryMessenger, "skarb_plugin")
    channel.setMethodCallHandler(this)
  }

  override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
    if (call.method == "initialize") {
     val clientKey = call.argument<String>("clientKey")
     val deviceId = call.argument<String>("deviceId")
     SkarbSDK.isLoggingEnabled = true
     SkarbSDK.initialize(application, clientKey!!, deviceId)
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
      SkarbSDK.sendSource(broker!!, features!!, brokerUserID)
      result.success(null)
    } else if (call.method == "syncPurchases") {
      SkarbSDK.syncPurchases()
      result.success(null)
    } else {
      result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
  }
}
