import 'button_style.dart';

/// Session configuration - can be client-side or server-side
abstract class KlarnaSessionConfig {
  Map<String, dynamic> toMap();
}

/// Client-side session configuration
class KlarnaClientSideSession extends KlarnaSessionConfig {
  final String clientId;
  final String locale;
  final String sessionData;
  final String region;
  final bool? collectShippingAddress;
  KlarnaClientSideSession({
    required this.clientId,
    required this.locale,
    required this.sessionData,
    required this.region,
    this.collectShippingAddress,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'sessionType': 'clientSide',
      'clientId': clientId,
      'locale': locale,
      'sessionData': sessionData,
      'region': region,
      if (collectShippingAddress != null) 'collectShippingAddress': collectShippingAddress,
    };
  }
}

/// Server-side session configuration
class KlarnaServerSideSession extends KlarnaSessionConfig {
  final String clientToken;
  final String locale;

  KlarnaServerSideSession({
    required this.clientToken,
    required this.locale,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'sessionType': 'serverSide',
      'clientToken': clientToken,
      'locale': locale,
    };
  }
}

/// Main configuration for Klarna Express Checkout
class KlarnaExpressCheckoutConfig {
  final KlarnaSessionConfig sessionConfig;
  final KlarnaButtonConfig buttonConfig;
  final KlarnaEnvironment environment;
  final String? returnUrl; // iOS specific

  KlarnaExpressCheckoutConfig({
    required this.sessionConfig,
    this.buttonConfig = const KlarnaButtonConfig(),
    this.environment = KlarnaEnvironment.production,
    this.returnUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      ...sessionConfig.toMap(),
      ...buttonConfig.toMap(),
      'environment': environment.name,
      if (returnUrl != null) 'returnUrl': returnUrl,
    };
  }
}
