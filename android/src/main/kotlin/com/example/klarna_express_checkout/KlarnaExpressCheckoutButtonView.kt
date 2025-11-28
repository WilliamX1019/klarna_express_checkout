package com.example.klarna_express_checkout

import android.content.Context
import android.view.View
import android.widget.FrameLayout
import com.klarna.mobile.sdk.api.expresscheckout.KlarnaExpressCheckoutButton
import com.klarna.mobile.sdk.api.expresscheckout.KlarnaExpressCheckoutButtonAuthorizationResponse
import com.klarna.mobile.sdk.api.expresscheckout.KlarnaExpressCheckoutButtonCallback
import com.klarna.mobile.sdk.api.expresscheckout.KlarnaExpressCheckoutButtonOptions
import com.klarna.mobile.sdk.api.expresscheckout.KlarnaExpressCheckoutButtonStyleConfiguration
import com.klarna.mobile.sdk.api.expresscheckout.KlarnaExpressCheckoutError
import com.klarna.mobile.sdk.api.expresscheckout.KlarnaExpressCheckoutSessionOptions
import com.klarna.mobile.sdk.api.button.KlarnaButtonTheme
import com.klarna.mobile.sdk.api.button.KlarnaButtonShape
import com.klarna.mobile.sdk.api.button.KlarnaButtonStyle
import com.klarna.mobile.sdk.api.KlarnaEnvironment
import com.klarna.mobile.sdk.api.KlarnaLoggingLevel
import com.klarna.mobile.sdk.api.KlarnaRegion
import com.klarna.mobile.sdk.api.KlarnaTheme
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class KlarnaExpressCheckoutButtonFactory(
    private val messenger: BinaryMessenger,
    private val plugin: KlarnaExpressCheckoutPlugin
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {

    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        return KlarnaExpressCheckoutButtonView(
            context!!,
            viewId,
            args as? Map<String, Any>,
            plugin
        )
    }
}

class KlarnaExpressCheckoutButtonView(
    private val context: Context,
    private val viewId: Int,
    private val config: Map<String, Any>?,
    private val plugin: KlarnaExpressCheckoutPlugin
) : PlatformView, KlarnaExpressCheckoutButtonCallback {

    private val containerView: FrameLayout = FrameLayout(context)
    private var klarnaButton: KlarnaExpressCheckoutButton? = null

    init {
        setupButton()
        // Register this view with the plugin
        plugin.registerButtonView(this, viewId)
    }

    private fun setupButton() {
        try {
            if (config == null) {
                sendError("invalidConfiguration", "Missing configuration for button", false)
                return
            }

            // Parse configuration
            val sessionType = config["sessionType"] as? String ?: "clientSide"
            val locale = config["locale"] as? String ?: "en-US"
            val returnUrl = config["returnUrl"] as? String ?: ""
            val environmentString = config["environment"] as? String ?: "production"
            val themeString = config["theme"] as? String ?: "dark"
            val regionString = config["region"] as? String ?: "na"
            val loggingLevelString = config["loggingLevel"] as? String ?: "off"

            // Parse session options
            val sessionOptions: KlarnaExpressCheckoutSessionOptions = when (sessionType.lowercase()) {
                "serverside" -> {
                    val clientToken = config["clientToken"] as? String
                    if (clientToken.isNullOrBlank()) {
                        sendError("invalidConfiguration", "Missing client token for server-side session", true)
                        return
                    }
                    KlarnaExpressCheckoutSessionOptions.ServerSideSession(
                        clientToken = clientToken,
                        autoFinalize = true
                    )
                }
                else -> {
                    val clientId = config["clientId"] as? String
                    if (clientId.isNullOrBlank()) {
                        sendError("invalidConfiguration", "Missing client ID for client-side session", true)
                        return
                    }

                    // Build session data
                    val sessionDataMap = mutableMapOf<String, Any>()
                    (config["amount"] as? Double)?.let {
                        sessionDataMap["purchase_amount"] = (it * 100).toInt()
                    }
                    (config["currency"] as? String)?.let {
                        sessionDataMap["purchase_currency"] = it
                    }

                    // Convert to JSON string if needed
                    val sessionData = if (sessionDataMap.isNotEmpty()) {
                        org.json.JSONObject(sessionDataMap as Map<*, *>).toString()
                    } else {
                        ""
                    }

                    KlarnaExpressCheckoutSessionOptions.ClientSideSession(
                        clientId = clientId,
                        sessionData = sessionData,
                        autoFinalize = true,
                        collectShippingAddress = config["collectShippingAddress"] as? Boolean ?: false
                    )
                }
            }

            // Parse environment
            val environment = when (environmentString.lowercase()) {
                "sandbox", "playground" -> KlarnaEnvironment.PLAYGROUND
                else -> KlarnaEnvironment.PRODUCTION
            }

            // Parse theme (KlarnaTheme for button options)
            val theme = when (themeString.lowercase()) {
                "light" -> KlarnaTheme.LIGHT
                "auto", "automatic" -> KlarnaTheme.AUTOMATIC
                else -> KlarnaTheme.DARK
            }

            // Parse region
            val region = when (regionString.lowercase()) {
                "eu", "europe" -> KlarnaRegion.EU
                "oc", "oceania" -> KlarnaRegion.OC
                "na", "north_america", "northamerica" -> KlarnaRegion.NA
                else -> KlarnaRegion.NA
            }

            // Parse logging level
            val loggingLevel = when (loggingLevelString.lowercase()) {
                "verbose", "debug" -> KlarnaLoggingLevel.Verbose
                "error" -> KlarnaLoggingLevel.Error
                "off", "none" -> KlarnaLoggingLevel.Off
                else -> KlarnaLoggingLevel.Off
            }

            // Parse style configuration
            // Note: Flutter sends these as top-level config values
            val shapeString = config["shape"] as? String
            val styleString = config["buttonStyle"] as? String // Note: Flutter sends "buttonStyle"

            val styleConfiguration = KlarnaExpressCheckoutButtonStyleConfiguration(
                theme = parseTheme(themeString),
                shape = parseShape(shapeString),
                style = parseStyle(styleString)
            )

            // Create button options
            val options = KlarnaExpressCheckoutButtonOptions(
                sessionOptions = sessionOptions,
                callback = this,
                locale = locale,
                styleConfiguration = styleConfiguration,
                environment = environment,
                region = region,
                theme = theme,
                resourceEndpoint = null,
                loggingLevel = loggingLevel
            )

            // Create and add button
            klarnaButton = KlarnaExpressCheckoutButton(context, options)
            containerView.addView(
                klarnaButton,
                FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.WRAP_CONTENT
                )
            )

        } catch (e: Exception) {
            sendError("initializationError", e.message ?: "Unknown error during initialization", true)
        }
    }

    private fun parseTheme(theme: String?): KlarnaButtonTheme {
        return when (theme?.lowercase()) {
            "light" -> KlarnaButtonTheme.LIGHT
            "auto" -> KlarnaButtonTheme.AUTO
            else -> KlarnaButtonTheme.DARK
        }
    }

    private fun parseShape(shape: String?): KlarnaButtonShape {
        return when (shape?.lowercase()) {
            "rectangle" -> KlarnaButtonShape.RECTANGLE
            "pill" -> KlarnaButtonShape.PILL
            else -> KlarnaButtonShape.ROUNDED_RECT
        }
    }

    private fun parseStyle(style: String?): KlarnaButtonStyle {
        return when (style?.lowercase()) {
            "outlined" -> KlarnaButtonStyle.OUTLINED
            else -> KlarnaButtonStyle.FILLED
        }
    }

    // KlarnaExpressCheckoutButtonCallback implementation
    override fun onAuthorized(
        view: KlarnaExpressCheckoutButton,
        response: KlarnaExpressCheckoutButtonAuthorizationResponse
    ) {
        val data = mutableMapOf<String, Any>(
            "approved" to response.approved,
            "sessionId" to (response.sessionId ?: "")
        )

        response.authorizationToken?.let {
            data["authorizationToken"] = it
        }

        response.collectedShippingAddress?.let {
            data["shippingAddress"] = it
        }

        data["finalizeRequired"] = response.finalizeRequired

        plugin.sendEvent("authorized", data)
    }

    override fun onError(
        view: KlarnaExpressCheckoutButton,
        error: KlarnaExpressCheckoutError
    ) {
        val errorCode = mapErrorCode(error)
        sendError(errorCode, error.message ?: "Unknown error", error.isFatal)
    }

    private fun mapErrorCode(error: KlarnaExpressCheckoutError): String {
        val errorName = error.name.lowercase()

        // Map error types to error codes
        return when {
            errorName.contains("invalidclientid") -> "invalidClientId"
            errorName.contains("authorizationfailed") -> "authorizationFailed"
            errorName.contains("alreadyinprogress") -> "alreadyInProgress"
            errorName.contains("buttonrenderfailed") -> "buttonRenderFailed"
            errorName.contains("network") -> "networkError"
            errorName.contains("session") -> "sessionError"
            errorName.contains("token") -> "tokenError"
            errorName.contains("cancelled") -> "cancelled"
            else -> "unknown"
        }
    }

    private fun sendError(code: String, message: String, isFatal: Boolean) {
        plugin.sendEvent("error", mapOf(
            "code" to code,
            "message" to message,
            "isFatal" to isFatal
        ))
    }

    override fun getView(): View = containerView

    override fun dispose() {
        // Unregister when the view is disposed
        plugin.unregisterButtonView(viewId)
        containerView.removeAllViews()
        klarnaButton = null
    }

    // Public methods for plugin
    fun updateSession(clientToken: String) {
        // Note: KlarnaExpressCheckoutButton doesn't support updating session after creation
        sendError("notSupported", "Session update not supported. Please recreate the button.", false)
    }

    fun finalizeSession() {
        // Express Checkout button handles finalization automatically via autoFinalize option
        sendError("notSupported", "Manual finalization not needed with autoFinalize enabled", false)
    }

    fun setLoggingLevel(level: String) {
        // Note: Logging level is set during button initialization
        sendError("notSupported", "Logging level can only be set during button initialization", false)
    }
}
