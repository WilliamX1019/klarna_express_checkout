# Klarna Express Checkout Flutter Plugin

A Flutter plugin for integrating Klarna Express Checkout into your mobile applications. Supports both iOS and Android platforms.

## Features

- ✅ **Full iOS Support** - Complete implementation with KlarnaExpressCheckoutButton
- ✅ **Full Android Support** - Complete implementation with Klarna Mobile SDK
- ✅ **Server-Side Sessions** - Secure token-based integration
- ✅ **Client-Side Sessions** - Quick setup with client ID
- ✅ **Customizable Styling** - Themes, shapes, and styles
- ✅ **Region Support** - NA, EU, and OC regions
- ✅ **Debug Logging** - Configurable logging levels
- ✅ **Comprehensive Error Handling** - Detailed error codes and messages
- ✅ **Deep Link Support** - Handle external app redirects
- ✅ **Shipping Address Collection** - Optional shipping data collection

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  klarna_express_checkout: ^0.1.0
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### iOS Setup

See the [iOS Setup Guide](IOS_SETUP.md) for detailed instructions on:
- Info.plist configuration
- Custom URL scheme setup
- Return URL handling
- App queries configuration

### Android Setup

See the [Android Setup Guide](ANDROID_SETUP.md) for detailed instructions on:
- Maven repository configuration
- AndroidManifest.xml setup
- Deep link handling
- ProGuard rules

## Quick Start

### Basic Usage

```dart
import 'package:klarna_express_checkout/klarna_express_checkout.dart';

KlarnaExpressCheckoutButton(
  // Session configuration
  sessionType: 'serverSide',
  clientToken: 'your_client_token',  // From your backend
  returnUrl: 'yourapp://',

  // Environment
  environment: 'playground',  // Use 'production' for live

  // Callbacks
  onAuthorized: (response) {
    print('Authorization token: ${response.authorizationToken}');
    // Send token to backend to create order
  },
  onError: (error) {
    print('Error: ${error.code} - ${error.message}');
  },
)
```

### Server-Side Session (Recommended)

```dart
// 1. Get client token from your backend
final clientToken = await fetchClientTokenFromBackend();

// 2. Create button with client token
KlarnaExpressCheckoutButton(
  sessionType: 'serverSide',
  clientToken: clientToken,
  returnUrl: 'yourapp://',
  environment: 'playground',
  onAuthorized: (response) async {
    // 3. Send authorization token to backend
    await createOrderOnBackend(response.authorizationToken);
  },
  onError: (error) {
    // Handle error
  },
)
```

### Client-Side Session

```dart
KlarnaExpressCheckoutButton(
  sessionType: 'clientSide',
  clientId: 'your_client_id',  // From Klarna Merchant Portal
  amount: 99.99,
  currency: 'USD',
  returnUrl: 'yourapp://',
  environment: 'playground',
  collectShippingAddress: true,
  onAuthorized: (response) async {
    // Send token to backend
    await createOrderOnBackend(
      response.authorizationToken,
      shippingAddress: response.shippingAddress,
    );
  },
  onError: (error) {
    // Handle error
  },
)
```

## Configuration Options

### Button Styling

```dart
KlarnaExpressCheckoutButton(
  // Theme
  theme: 'dark',  // 'dark', 'light', or 'auto'

  // Style configuration (Android only)
  styleConfiguration: {
    'shape': 'rounded_rect',  // 'rectangle', 'rounded_rect', 'pill'
    'style': 'filled',        // 'filled', 'outlined'
    'cornerRadius': 8.0,      // iOS only
    'height': 50.0,           // iOS only
  },

  // Region
  region: 'na',  // 'na', 'eu', 'oc'

  // Locale
  locale: 'en-US',

  // Logging
  loggingLevel: 'verbose',  // 'off', 'error', 'verbose'

  // ... other options
)
```

### Environment

- `playground` - Test environment (use test credentials)
- `production` - Live environment

### Regions

- `na` - North America (default)
- `eu` - Europe
- `oc` - Oceania

## Error Handling

```dart
KlarnaExpressCheckoutButton(
  onError: (error) {
    switch (error.code) {
      case 'authorizationFailed':
        // Handle authorization failure
        break;
      case 'networkError':
        // Handle network issues
        break;
      case 'sessionExpired':
        // Session expired, get new token
        break;
      case 'invalidConfiguration':
        // Check your configuration
        break;
      case 'cancelled':
        // User cancelled
        break;
      default:
        // Handle other errors
        print('Error: ${error.message}');
    }
  },
)
```

### Common Error Codes

- `authorizationFailed` - Payment authorization failed
- `networkError` - Network connection issue
- `sessionExpired` - Session has expired
- `invalidSession` - Invalid session data
- `tokenExpired` - Authorization token expired
- `invalidToken` - Invalid token
- `invalidConfiguration` - Configuration error
- `cancelled` - User cancelled the flow
- `timeout` - Request timed out
- `serverError` - Server error (5xx)
- `clientError` - Client error (4xx)
- `paymentError` - Payment processing error

## Backend Integration

After receiving the authorization token, create an order on your backend:

```dart
Future<void> createOrderOnBackend(String authToken) async {
  final response = await http.post(
    Uri.parse('https://api.klarna.com/payments/v1/authorizations/$authToken/order'),
    headers: {
      'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'purchase_country': 'US',
      'purchase_currency': 'USD',
      'locale': 'en-US',
      'order_amount': 9999,
      'order_lines': [
        {
          'name': 'Product Name',
          'quantity': 1,
          'unit_price': 9999,
          'total_amount': 9999,
        }
      ],
      'merchant_urls': {
        'confirmation': 'https://example.com/confirmation',
      },
    }),
  );

  if (response.statusCode == 200) {
    final order = jsonDecode(response.body);
    print('Order created: ${order['order_id']}');
  }
}
```

**Important**: Authorization tokens expire after 60 minutes.

## API Reference

### KlarnaExpressCheckoutButton

Main widget for displaying the Klarna Express Checkout button.

#### Required Parameters

- `returnUrl` (String) - Your app's custom URL scheme
- `sessionType` (String) - 'serverSide' or 'clientSide'
- One of:
  - `clientToken` (String) - For server-side sessions
  - `clientId` (String) - For client-side sessions

#### Optional Parameters

- `environment` (String) - 'playground' or 'production' (default: 'production')
- `region` (String) - 'na', 'eu', or 'oc' (default: 'na')
- `theme` (String) - 'dark', 'light', or 'auto' (default: 'dark')
- `locale` (String) - Button text language (default: 'en-US')
- `loggingLevel` (String) - 'off', 'error', or 'verbose' (default: 'off')
- `collectShippingAddress` (bool) - Collect shipping address (default: false)
- `styleConfiguration` (Map) - Custom styling options
- `amount` (double) - Purchase amount (client-side only)
- `currency` (String) - Purchase currency (client-side only)

#### Callbacks

- `onAuthorized(AuthorizationResponse)` - Called when authorization succeeds
- `onError(KlarnaError)` - Called when an error occurs

### AuthorizationResponse

Response object from successful authorization.

#### Properties

- `approved` (bool) - Whether authorization was approved
- `authorizationToken` (String?) - Token for creating order
- `sessionId` (String?) - Klarna session ID
- `shippingAddress` (Map?) - Collected shipping address
- `finalizeRequired` (bool) - Whether finalization is required

### KlarnaError

Error object passed to `onError` callback.

#### Properties

- `code` (String) - Error code (see error codes above)
- `message` (String) - Error message
- `isFatal` (bool) - Whether the error is fatal
- `debugMessage` (String?) - Additional debug information

## Best Practices

1. **Use Server-Side Sessions in Production**
   - More secure
   - Better control over session data
   - Recommended by Klarna

2. **Implement Proper Error Handling**
   - Handle all error types
   - Show user-friendly messages
   - Log errors for debugging

3. **Test Thoroughly**
   - Use playground environment for testing
   - Test all payment scenarios
   - Test error cases

4. **Keep SDK Updated**
   - Update plugin regularly
   - Follow Klarna's versioning policy
   - Check for breaking changes

5. **Secure Your Backend**
   - Never expose API credentials in app
   - Validate all requests
   - Use HTTPS

6. **Handle Token Expiration**
   - Create orders within 60 minutes
   - Handle expired token errors
   - Request new authorization if needed

## Troubleshooting

### Button doesn't appear

1. Check configuration parameters
2. Verify API credentials
3. Check console logs for errors
4. Ensure proper SDK initialization

### Authorization fails

1. Verify session configuration
2. Check API credentials
3. Ensure proper environment setting
4. Check Klarna Merchant Portal settings

### Deep links don't work

1. Verify URL scheme configuration
2. Check platform-specific setup
3. Test return URL handling
4. See platform setup guides

## Examples

See the `/example` directory for a complete working example.

## Requirements

- Flutter SDK: >=2.12.0
- iOS: 12.0+
- Android: API 21+ (Lollipop)

## Documentation

- [iOS Setup Guide](IOS_SETUP.md)
- [Android Setup Guide](ANDROID_SETUP.md)
- [Klarna Official Documentation](https://docs.klarna.com/)

## Support

For issues related to:
- **Plugin implementation**: Open an issue on GitHub
- **Klarna API**: Contact Klarna Support
- **Merchant Portal**: Visit [portal.klarna.com](https://portal.klarna.com/)

## License

[Add your license here]

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history.
