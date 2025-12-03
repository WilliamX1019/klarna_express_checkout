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

    func sendEvent(type: String, data: [String: Any]) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let eventSink = self.eventSink else {
                print("[KlarnaExpressCheckoutPlugin] Warning: eventSink is nil. Cannot send event: \(type)")
                return
            }
            print("[KlarnaExpressCheckoutPlugin] Sending event: \(type)")
            eventSink([
                "type": type,
                "data": data
            ])
        }
    }

    func registerButtonView(_ view: KlarnaExpressCheckoutButtonView, viewId: Int64) {
        buttonViews[viewId] = view
    }
//
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
