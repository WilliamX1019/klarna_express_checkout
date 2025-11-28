import Flutter
import UIKit
import KlarnaMobileSDK

public class KlarnaExpressCheckoutPlugin: NSObject, FlutterPlugin {
    private var channel: FlutterMethodChannel?
    private var eventChannel: FlutterEventChannel?
    private var eventSink: FlutterEventSink?
    private var buttonViews: [Int64: KlarnaExpressCheckoutButtonView] = [:]

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "klarna_express_checkout",
            binaryMessenger: registrar.messenger()
        )

        let eventChannel = FlutterEventChannel(
            name: "klarna_express_checkout/events",
            binaryMessenger: registrar.messenger()
        )

        let instance = KlarnaExpressCheckoutPlugin()
        instance.channel = channel
        instance.eventChannel = eventChannel

        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)

        // Register platform view factory
        registrar.register(
            KlarnaExpressCheckoutButtonFactory(messenger: registrar.messenger(), plugin: instance),
            withId: "klarna_express_checkout_button"
        )
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "initialize":
            handleInitialize(call, result: result)
        case "loadButton":
            handleLoadButton(call, result: result)
        case "updateSession":
            handleUpdateSession(call, result: result)
        case "finalizeSession":
            handleFinalizeSession(call, result: result)
        case "setLoggingLevel":
            handleSetLoggingLevel(call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func handleInitialize(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid arguments for initialize",
                details: nil
            ))
            return
        }

        // Extract configuration
        let environment = args["environment"] as? String ?? "production"

        // Set up Klarna environment if needed
        // (SDK initialization is typically done per-button)

        result(nil)
    }

    private func handleLoadButton(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        // Button loading is handled by the platform view
        result(nil)
    }

    private func handleUpdateSession(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid arguments for updateSession",
                details: nil
            ))
            return
        }

        guard let viewId = args["viewId"] as? Int64,
              let clientToken = args["clientToken"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing viewId or clientToken for updateSession",
                details: nil
            ))
            return
        }

        guard let buttonView = buttonViews[viewId] else {
            result(FlutterError(
                code: "VIEW_NOT_FOUND",
                message: "Button view with id \(viewId) not found",
                details: nil
            ))
            return
        }

        buttonView.updateSession(clientToken: clientToken)
        result(nil)
    }

    private func handleFinalizeSession(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let viewId = args["viewId"] as? Int64 else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing viewId for finalizeSession",
                details: nil
            ))
            return
        }

        guard let buttonView = buttonViews[viewId] else {
            result(FlutterError(
                code: "VIEW_NOT_FOUND",
                message: "Button view with id \(viewId) not found",
                details: nil
            ))
            return
        }

        buttonView.finalizeSession()
        result(nil)
    }

    private func handleSetLoggingLevel(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let level = args["level"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Invalid arguments for setLoggingLevel",
                details: nil
            ))
            return
        }

        guard let viewId = args["viewId"] as? Int64 else {
            result(FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing viewId for setLoggingLevel",
                details: nil
            ))
            return
        }

        guard let buttonView = buttonViews[viewId] else {
            result(FlutterError(
                code: "VIEW_NOT_FOUND",
                message: "Button view with id \(viewId) not found",
                details: nil
            ))
            return
        }

        buttonView.setLoggingLevel(level)
        result(nil)
    }

    func sendEvent(type: String, data: [String: Any]) {
        guard let eventSink = eventSink else { return }
        eventSink([
            "type": type,
            "data": data
        ])
    }

    func registerButtonView(_ view: KlarnaExpressCheckoutButtonView, viewId: Int64) {
        buttonViews[viewId] = view
    }

    func unregisterButtonView(viewId: Int64) {
        buttonViews.removeValue(forKey: viewId)
    }
}

// MARK: - FlutterStreamHandler
extension KlarnaExpressCheckoutPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }

    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
