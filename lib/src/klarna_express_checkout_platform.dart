import 'package:flutter/services.dart';
import 'models/authorization_result.dart';
import 'models/klarna_error.dart';

/// Platform interface for Klarna Express Checkout
class KlarnaExpressCheckoutPlatform {
  static const MethodChannel _channel =
      MethodChannel('klarna_express_checkout');

  static const EventChannel _eventChannel =
      EventChannel('klarna_express_checkout/events');

  /// Stream of authorization results
  Stream<Map<dynamic, dynamic>>? _eventStream;

  Stream<Map<dynamic, dynamic>> get eventStream {
    _eventStream ??= _eventChannel.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();
    return _eventStream!;
  }

  /// Initialize the Klarna SDK with configuration
  // Future<void> initialize(Map<String, dynamic> config) async {
  //   try {
  //     await _channel.invokeMethod('initialize', config);
  //   } on PlatformException catch (e) {
  //     throw KlarnaError(
  //       code: KlarnaErrorCode.invalidConfiguration,
  //       message: e.message ?? 'Failed to initialize',
  //       debugMessage: e.details?.toString(),
  //     );
  //   }
  // }

  /// Load the Express Checkout button
  // Future<void> loadButton(Map<String, dynamic> config) async {
  //   try {
  //     await _channel.invokeMethod('loadButton', config);
  //   } on PlatformException catch (e) {
  //     throw KlarnaError(
  //       code: KlarnaErrorCode.invalidConfiguration,
  //       message: e.message ?? 'Failed to load button',
  //       debugMessage: e.details?.toString(),
  //     );
  //   }
  // }

  /// Update session data (for client-side sessions)
  // Future<void> updateSession(Map<String, dynamic> sessionData) async {
  //   try {
  //     await _channel.invokeMethod('updateSession', sessionData);
  //   } on PlatformException catch (e) {
  //     throw KlarnaError(
  //       code: KlarnaErrorCode.invalidConfiguration,
  //       message: e.message ?? 'Failed to update session',
  //       debugMessage: e.details?.toString(),
  //     );
  //   }
  // }

  /// Finalize the session manually (when autoFinalize is false)
  // Future<void> finalizeSession() async {
  //   try {
  //     await _channel.invokeMethod('finalizeSession');
  //   } on PlatformException catch (e) {
  //     throw KlarnaError(
  //       code: KlarnaErrorCode.authorizationFailed,
  //       message: e.message ?? 'Failed to finalize session',
  //       debugMessage: e.details?.toString(),
  //     );
  //   }
  // }

  /// Enable logging for debugging
  // Future<void> setLoggingLevel(String level) async {
  //   try {
  //     await _channel.invokeMethod('setLoggingLevel', {'level': level});
  //   } on PlatformException catch (e) {
  //     throw KlarnaError(
  //       code: KlarnaErrorCode.unknown,
  //       message: e.message ?? 'Failed to set logging level',
  //       debugMessage: e.details?.toString(),
  //     );
  //   }
  // }
}
