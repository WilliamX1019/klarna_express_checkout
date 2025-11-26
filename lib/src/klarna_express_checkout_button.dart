import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'models/express_checkout_config.dart';
import 'models/authorization_result.dart';
import 'models/klarna_error.dart';
import 'klarna_express_checkout_platform.dart';

/// Callback for successful authorization
typedef OnAuthorizedCallback = void Function(AuthorizationResult result);

/// Callback for errors
typedef OnErrorCallback = void Function(KlarnaError error);

/// Klarna Express Checkout Button Widget
class KlarnaExpressCheckoutButton extends StatefulWidget {
  final KlarnaExpressCheckoutConfig config;
  final OnAuthorizedCallback onAuthorized;
  final OnErrorCallback onError;
  final double? width;
  final double height;

  const KlarnaExpressCheckoutButton({
    Key? key,
    required this.config,
    required this.onAuthorized,
    required this.onError,
    this.width,
    this.height = 50.0,
  }) : super(key: key);

  @override
  State<KlarnaExpressCheckoutButton> createState() =>
      _KlarnaExpressCheckoutButtonState();
}

class _KlarnaExpressCheckoutButtonState
    extends State<KlarnaExpressCheckoutButton> {
  final KlarnaExpressCheckoutPlatform _platform =
      KlarnaExpressCheckoutPlatform();

  late final String _viewId;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _viewId = 'klarna_button_${widget.hashCode}';
    _initializeButton();
    _listenToEvents();
  }

  Future<void> _initializeButton() async {
    try {
      await _platform.initialize(widget.config.toMap());
      await _platform.loadButton(widget.config.toMap());
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      widget.onError(
        KlarnaError(
          code: KlarnaErrorCode.invalidConfiguration,
          message: 'Failed to initialize button',
          debugMessage: e.toString(),
        ),
      );
    }
  }

  void _listenToEvents() {
    _platform.eventStream.listen(
      (event) {
        final eventType = event['type'] as String?;

        if (eventType == 'authorized') {
          final result = AuthorizationResult.fromMap(event['data'] as Map);
          widget.onAuthorized(result);
        } else if (eventType == 'error') {
          final error = KlarnaError.fromMap(event['data'] as Map);
          widget.onError(error);
        }
      },
      onError: (error) {
        widget.onError(
          KlarnaError(
            code: KlarnaErrorCode.unknown,
            message: 'Event stream error',
            debugMessage: error.toString(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        width: widget.width,
        height: widget.height,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    Widget platformView;

    // Use platform-specific view
    if (Theme.of(context).platform == TargetPlatform.iOS) {
      platformView = UiKitView(
        viewType: 'klarna_express_checkout_button',
        creationParams: widget.config.toMap(),
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else if (Theme.of(context).platform == TargetPlatform.android) {
      platformView = AndroidView(
        viewType: 'klarna_express_checkout_button',
        creationParams: widget.config.toMap(),
        creationParamsCodec: const StandardMessageCodec(),
      );
    } else {
      platformView = const Center(
        child: Text('Platform not supported'),
      );
    }

    // Wrap in Container with tight constraints to enforce size
    return Container(
      width: widget.width,
      height: widget.height,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(),
      child: platformView,
    );
  }
}
