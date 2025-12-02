import Flutter
import UIKit
import KlarnaMobileSDK

class KlarnaExpressCheckoutButtonFactory: NSObject, FlutterPlatformViewFactory {
    private var messenger: FlutterBinaryMessenger
    private weak var plugin: KlarnaExpressCheckoutPlugin?

    init(messenger: FlutterBinaryMessenger, plugin: KlarnaExpressCheckoutPlugin) {
        self.messenger = messenger
        self.plugin = plugin
        super.init()
    }

    func create(
        withFrame frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?
    ) -> FlutterPlatformView {
        return KlarnaExpressCheckoutButtonView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            messenger: messenger,
            plugin: plugin
        )
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class KlarnaExpressCheckoutButtonView: NSObject, FlutterPlatformView {
    private var _view: UIView
    private var button: KlarnaExpressCheckoutButton?
    private weak var plugin: KlarnaExpressCheckoutPlugin?
    private let viewId: Int64

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger,
        plugin: KlarnaExpressCheckoutPlugin?
    ) {
        _view = UIView(frame: frame)
        self.plugin = plugin
        self.viewId = viewId
        super.init()

        guard let args = args as? [String: Any] else {
            return
        }

        setupButton(with: args)

        // Register this view with the plugin
        plugin?.registerButtonView(self, viewId: viewId)
    }

    func view() -> UIView {
        return _view
    }

    deinit {
        // Unregister when the view is deallocated
        plugin?.unregisterButtonView(viewId: viewId)
    }

    private func setupButton(with config: [String: Any]) {
        // Parse configuration
        let sessionType = config["sessionType"] as? String ?? "clientSide"
        let locale = config["locale"] as? String ?? "en-US"
        let returnUrlString = config["returnUrl"] as? String ?? ""
        let environmentString = config["environment"] as? String ?? "production"
        let themeString = config["theme"] as? String ?? "dark"
        let regionString = config["region"] as? String ?? "na"
        let loggingLevelString = config["loggingLevel"] as? String ?? "off"
        let sessionData:String = config["sessionData"] as? String ?? ""



        // Parse session options
        let sessionOptions: KlarnaExpressCheckoutSessionOptions

        if sessionType == "serverSide" {
            // Server-side session
            guard let clientToken = config["clientToken"] as? String else {
                sendError(message: "Missing client token for server-side session")
                return
            }

            sessionOptions = KlarnaExpressCheckoutSessionOptions.ServerSideSession(
                clientToken: clientToken,
                autoFinalize: true
            )
        } else {
            // Client-side session
            guard let clientId = config["clientId"] as? String else {
                sendError(message: "Missing client ID for client-side session")
                return
            }

            // Build session data dictionary
            // var sessionData: [String: Any] = [:]
            // if let amount = config["amount"] as? Double {
            //     sessionData["purchase_amount"] = Int(amount * 100) // Convert to minor units
            // }
            // if let currency = config["currency"] as? String {
            //     sessionData["purchase_currency"] = currency
            // }

            // // Convert session data to JSON string if needed
            // var sessionDataString: String? = nil
            // if !sessionData.isEmpty,
            //    let jsonData = try? JSONSerialization.data(withJSONObject: sessionData),
            //    let jsonString = String(data: jsonData, encoding: .utf8) {
            //     sessionDataString = jsonString
            // }

            sessionOptions = KlarnaExpressCheckoutSessionOptions.ClientSideSession(
                clientId: clientId,
                sessionData: sessionData,
                autoFinalize: true,
                collectShippingAddress: config["collectShippingAddress"] as? Bool ?? false
            )
        }

        // Parse environment
        let environment: KlarnaEnvironment
        switch environmentString.lowercased() {
        case "sandbox", "playground":
            environment = .playground
        default:
            environment = .production
        }

        // Parse theme (for button options - KlarnaTheme)
        let theme: KlarnaTheme
        switch themeString.lowercased() {
        case "light":
            theme = .light
        case "auto", "automatic":
            theme = .automatic
        default:
            theme = .dark
        }

        // Parse region
        let region: KlarnaRegion
        switch regionString.lowercased() {
        case "eu", "europe":
            region = .eu
        case "oc", "oceania":
            region = .oc
        case "na", "north_america", "northamerica":
            region = .na
        default:
            region = .na // Default to North America
        }

        // Parse logging level
        let loggingLevel: KlarnaLoggingLevel
        switch loggingLevelString.lowercased() {
        case "verbose", "debug":
            loggingLevel = .verbose
        case "error":
            loggingLevel = .error
        case "off", "none":
            loggingLevel = .off
        default:
            loggingLevel = .off
        }

        // Parse style configuration
        // Note: Flutter sends these as top-level config values, not nested in styleConfiguration
        var buttonTheme: KlarnaButtonTheme? = nil
        var buttonShape: KlarnaButtonShape? = nil
        var buttonStyle: KlarnaButtonStyle? = nil

        // Parse button theme (KlarnaButtonTheme for style configuration)
        // This is different from the overall theme (KlarnaTheme) used above
        // We use the same 'theme' value for consistency
        switch themeString.lowercased() {
        case "light":
            buttonTheme = .light
        case "dark":
            buttonTheme = .dark
        case "auto", "automatic":
            buttonTheme = .auto
        default:
            buttonTheme = nil
        }

        // Parse button shape
        if let shapeStr = config["shape"] as? String {
            switch shapeStr.lowercased() {
            case "pill":
                buttonShape = .pill
            case "rectangle":
                buttonShape = .rectangle
            case "roundedrect", "rounded_rect", "rounded":
                buttonShape = .roundedRect
            default:
                buttonShape = nil
            }
        }

        // Parse button style (note: Flutter sends as "buttonStyle" not "style")
        if let styleStr = config["buttonStyle"] as? String {
            switch styleStr.lowercased() {
            case "outlined", "outline":
                buttonStyle = .outlined
            case "filled", "fill":
                buttonStyle = .filled
            default:
                buttonStyle = nil
            }
        }

        // Create style configuration with parsed values
        let styleConfiguration = KlarnaExpressCheckoutButtonStyleConfiguration(
            theme: buttonTheme,
            shape: buttonShape,
            style: buttonStyle
        )

        // Build button options
        let options = KlarnaExpressCheckoutButtonOptions(
            sessionOptions: sessionOptions,
            returnUrl: returnUrlString,
            delegate: self,
            locale: locale,
            styleConfiguration: styleConfiguration,
            theme: theme,
            environment: environment,
            region: region,
            resourceEndpoint: nil,
            loggingLevel: loggingLevel
        )

        // Create button
        button = KlarnaExpressCheckoutButton(options: options)

        // Add button to view
        if let button = button {
            button.translatesAutoresizingMaskIntoConstraints = false
            _view.addSubview(button)

            NSLayoutConstraint.activate([
                button.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
                button.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
                button.topAnchor.constraint(equalTo: _view.topAnchor),
                button.bottomAnchor.constraint(equalTo: _view.bottomAnchor)
            ])
        }
    }

    private func sendError(message: String, isFatal: Bool = false) {
        plugin?.sendEvent(type: "error", data: [
            "code": "invalidConfiguration",
            "message": message,
            "isFatal": isFatal
        ])
    }
}

// MARK: - KlarnaExpressCheckoutButtonDelegate
extension KlarnaExpressCheckoutButtonView: KlarnaExpressCheckoutButtonDelegate {
    func onAuthorized(
        view: KlarnaMobileSDK.KlarnaExpressCheckoutButton,
        response: KlarnaMobileSDK.KlarnaExpressCheckoutButtonAuthorizationResponse
    ) {
        var data: [String: Any] = [
            "approved": response.approved,
            "sessionId": ""  // Session ID not directly exposed in response
        ]

        if let token = response.authorizationToken {
            data["authorizationToken"] = token
        }

        // Add shipping address if available - collectedShippingAddress is a String, not an object
        if let shippingAddressString = response.collectedShippingAddress,
           let shippingAddressData = shippingAddressString.data(using: .utf8),
           let shippingAddress = try? JSONSerialization.jsonObject(with: shippingAddressData) as? [String: Any] {
            data["shippingAddress"] = shippingAddress
        }

        plugin?.sendEvent(type: "authorized", data: data)
    }

    func onError(
        view: KlarnaMobileSDK.KlarnaExpressCheckoutButton,
        error: KlarnaMobileSDK.KlarnaError
    ) {
        plugin?.sendEvent(type: "error", data: [
            "code": mapErrorCode(error),
            "message": error.message,
            "isFatal": error.isFatal,
            "debugMessage": error.debugDescription
        ])
    }

    private func mapErrorCode(_ error: KlarnaError) -> String {
        // Map Klarna SDK error to our error codes
        let errorName = error.name.lowercased()

        // Authorization errors
        if errorName.contains("authorizationfailed") || errorName.contains("authorization_failed") {
            return "authorizationFailed"
        }

        // Network errors
        if errorName.contains("network") || errorName.contains("connection") {
            return "networkError"
        }

        // Configuration errors
        if errorName.contains("invalidconfiguration") || errorName.contains("invalid_configuration") {
            return "invalidConfiguration"
        }

        // User cancellation
        if errorName.contains("cancelled") || errorName.contains("canceled") {
            return "cancelled"
        }

        // Session errors
        if errorName.contains("session") {
            if errorName.contains("expired") {
                return "sessionExpired"
            } else if errorName.contains("invalid") {
                return "invalidSession"
            }
            return "sessionError"
        }

        // Token errors
        if errorName.contains("token") {
            if errorName.contains("expired") {
                return "tokenExpired"
            } else if errorName.contains("invalid") {
                return "invalidToken"
            }
            return "tokenError"
        }

        // Timeout errors
        if errorName.contains("timeout") || errorName.contains("timed out") {
            return "timeout"
        }

        // Server errors
        if errorName.contains("server") || errorName.contains("5xx") {
            return "serverError"
        }

        // Client errors
        if errorName.contains("client") || errorName.contains("4xx") {
            return "clientError"
        }

        // Payment method errors
        if errorName.contains("payment") {
            return "paymentError"
        }

        return "unknown"
    }

    // MARK: - Public Methods for Plugin

    func updateSession(clientToken: String) {
        // Note: KlarnaExpressCheckoutButton doesn't support updating session after creation
        // You would need to recreate the button with new options
        sendError(message: "Session update not supported for Express Checkout button. Please recreate the button.", isFatal: false)
    }

    func finalizeSession() {
        // Express Checkout button handles finalization automatically via autoFinalize option
        // This method is kept for API compatibility
        sendError(message: "Manual finalization not needed for Express Checkout with autoFinalize enabled", isFatal: false)
    }

    func setLoggingLevel(_ level: String) {
        // Note: Logging level is set during button initialization
        // It cannot be changed after the button is created
        sendError(message: "Logging level can only be set during button initialization", isFatal: false)
    }
}
