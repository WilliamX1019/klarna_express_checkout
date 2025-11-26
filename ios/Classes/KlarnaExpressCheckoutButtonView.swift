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

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        messenger: FlutterBinaryMessenger,
        plugin: KlarnaExpressCheckoutPlugin?
    ) {
        _view = UIView(frame: frame)
        self.plugin = plugin
        super.init()

        guard let args = args as? [String: Any] else {
            return
        }

        setupButton(with: args)
    }

    func view() -> UIView {
        return _view
    }

    private func setupButton(with config: [String: Any]) {
        // Parse configuration
        let sessionType = config["sessionType"] as? String ?? "clientSide"
        let locale = config["locale"] as? String ?? "en-US"
        let returnUrlString = config["returnUrl"] as? String ?? ""
        let environmentString = config["environment"] as? String ?? "production"

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
                autoFinalize: true,
                collectShippingAddress: false,
                sessionData: nil
            )
        } else {
            // Client-side session
            guard let clientId = config["clientId"] as? String else {
                sendError(message: "Missing client ID for client-side session")
                return
            }

            // Build session data dictionary
            var sessionData: [String: Any] = [:]
            if let amount = config["amount"] as? Double {
                sessionData["purchase_amount"] = Int(amount * 100) // Convert to minor units
            }
            if let currency = config["currency"] as? String {
                sessionData["purchase_currency"] = currency
            }

            // Convert session data to JSON string if needed
            var sessionDataString: String? = nil
            if !sessionData.isEmpty,
               let jsonData = try? JSONSerialization.data(withJSONObject: sessionData),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                sessionDataString = jsonString
            }

            sessionOptions = KlarnaExpressCheckoutSessionOptions.ClientSideSession(
                clientId: clientId,
                sessionData: sessionDataString ?? "",
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

        // Build button options
        let options = KlarnaExpressCheckoutButtonOptions(
            sessionOptions: sessionOptions,
            returnUrl: returnUrlString,
            delegate: self,
            locale: locale,
            styleConfiguration: nil, // Will use defaults or set separately if needed
            theme: .dark,
            environment: environment,
            region: .na,
            resourceEndpoint: nil,
            loggingLevel: .off
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
        let errorName = error.name

        if errorName.contains("AuthorizationFailed") {
            return "authorizationFailed"
        } else if errorName.contains("Network") {
            return "networkError"
        } else if errorName.contains("InvalidConfiguration") {
            return "invalidConfiguration"
        } else if errorName.contains("Cancelled") {
            return "cancelled"
        }

        return "unknown"
    }
}
