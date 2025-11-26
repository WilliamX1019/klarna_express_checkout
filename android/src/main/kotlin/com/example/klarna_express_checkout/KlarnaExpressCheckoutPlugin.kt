package com.example.klarna_express_checkout

import android.content.Context
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.platform.PlatformViewRegistry

class KlarnaExpressCheckoutPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private lateinit var context: Context

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext

        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "klarna_express_checkout")
        channel.setMethodCallHandler(this)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "klarna_express_checkout/events")
        eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })

        // Register platform view factory
        flutterPluginBinding
            .platformViewRegistry
            .registerViewFactory(
                "klarna_express_checkout_button",
                KlarnaExpressCheckoutButtonFactory(flutterPluginBinding.binaryMessenger, this)
            )
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        when (call.method) {
            "initialize" -> handleInitialize(call, result)
            "loadButton" -> handleLoadButton(call, result)
            "updateSession" -> handleUpdateSession(call, result)
            "finalizeSession" -> handleFinalizeSession(call, result)
            "setLoggingLevel" -> handleSetLoggingLevel(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleInitialize(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val environment = args?.get("environment") as? String ?: "production"

            // Initialize Klarna SDK if needed
            // Most initialization is done per-button

            result.success(null)
        } catch (e: Exception) {
            result.error("INITIALIZATION_ERROR", e.message, null)
        }
    }

    private fun handleLoadButton(call: MethodCall, result: Result) {
        // Button loading is handled by the platform view
        result.success(null)
    }

    private fun handleUpdateSession(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            // Update session logic here
            result.success(null)
        } catch (e: Exception) {
            result.error("UPDATE_SESSION_ERROR", e.message, null)
        }
    }

    private fun handleFinalizeSession(call: MethodCall, result: Result) {
        try {
            // Finalize session logic here
            result.success(null)
        } catch (e: Exception) {
            result.error("FINALIZE_ERROR", e.message, null)
        }
    }

    private fun handleSetLoggingLevel(call: MethodCall, result: Result) {
        try {
            val args = call.arguments as? Map<String, Any>
            val level = args?.get("level") as? String
            // Set logging level
            result.success(null)
        } catch (e: Exception) {
            result.error("LOGGING_ERROR", e.message, null)
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    fun sendEvent(type: String, data: Map<String, Any>) {
        eventSink?.success(mapOf(
            "type" to type,
            "data" to data
        ))
    }
}
