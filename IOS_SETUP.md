# iOS Setup Guide for Klarna Express Checkout

This guide covers the iOS-specific setup required for the Klarna Express Checkout Flutter plugin.

## Prerequisites

- iOS 13.0 or higher (KlarnaMobileSDK supports iOS 10.0+, but this plugin requires iOS 13.0+)
- Xcode 13 or higher
- CocoaPods or Swift Package Manager

## Required iOS Configuration

### 1. Info.plist Configuration

Add the following to your iOS app's `Info.plist` file to enable querying the Klarna app:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>klarna</string>
    <string>klarnaconsent</string>
</array>
```

**Location**: `ios/Runner/Info.plist`

**Why needed**: This allows your app to check if the Klarna app is installed and to redirect users to the Klarna app when needed for authentication or payment flows.

### 2. Custom URL Scheme Configuration

Klarna flows may redirect to external apps (banking apps, identity verification apps). You need to configure a custom URL scheme so these external apps can return to your app.

#### Option A: Using Info.plist

Add the following to your `Info.plist`:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLName</key>
        <string>com.yourcompany.yourapp</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>yourappscheme</string>
        </array>
    </dict>
</array>
```

Replace `yourappscheme` with your app's unique URL scheme (e.g., `myshop`, `myapp`, etc.).

#### Option B: Using Xcode

1. Open your project in Xcode
2. Select your app target
3. Go to the "Info" tab
4. Expand "URL Types"
5. Click "+" to add a new URL type
6. Set:
   - **Identifier**: Your app's bundle identifier
   - **URL Schemes**: Your custom scheme (e.g., `myapp`)
   - **Role**: Editor

### 3. Return URL Handling in Code

#### For Apps Using SceneDelegate (iOS 13+)

Add this to your `SceneDelegate.swift`:

```swift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }

        // Define your Klarna return URL
        let klarnaReturnUrl = "yourappscheme://"

        // Check if this is a Klarna return URL
        if url.absoluteString.starts(with: klarnaReturnUrl) {
            // Let Klarna SDK handle the return
            // No additional processing needed
            return
        }

        // Handle other deep links here
        // ... your other deep link handling code
    }
}
```

#### For Apps Using AppDelegate (iOS 12 or legacy apps)

Add this to your `AppDelegate.swift`:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {

        // Define your Klarna return URL
        let klarnaReturnUrl = "yourappscheme://"

        // Check if this is a Klarna return URL
        if url.absoluteString.starts(with: klarnaReturnUrl) {
            // Let Klarna SDK handle the return
            return true
        }

        // Handle other deep links or let Flutter handle it
        return super.application(app, open: url, options: options)
    }
}
```

## Flutter Configuration

When initializing the Klarna Express Checkout button in Flutter, make sure to pass the same return URL:

```dart
KlarnaExpressCheckoutButton(
  returnUrl: 'yourappscheme://', // Must match your URL scheme
  clientToken: 'your_client_token',
  environment: KlarnaEnvironment.playground,
  // ... other options
)
```

**Important**: The return URL must include `://` (e.g., `"myapp://"`, not just `"myapp"`).

## Theme Configuration

The button theme can now be configured:

```dart
KlarnaExpressCheckoutButton(
  theme: 'light', // or 'dark' (default)
  // ... other options
)
```

## Logging Configuration

For debugging, you can set the logging level during button initialization:

```dart
KlarnaExpressCheckoutButton(
  loggingLevel: 'verbose', // 'off', 'error', or 'verbose'
  // ... other options
)
```

**Note**: The logging level can only be set during button creation and cannot be changed afterwards.

## Common Issues

### Issue: External redirect doesn't return to app

**Solution**:
1. Verify your URL scheme is correctly configured in Info.plist
2. Ensure the return URL passed to Klarna includes `://`
3. Check that your SceneDelegate/AppDelegate properly handles the URL

### Issue: "App can't open Klarna"

**Solution**:
1. Add `klarna` and `klarnaconsent` to `LSApplicationQueriesSchemes` in Info.plist
2. Clean and rebuild your project

### Issue: Button doesn't appear or shows blank space

**Solution**:
1. Check that you've provided valid client token or client ID
2. Verify the environment setting (playground for testing, production for live)
3. Check the console logs for error messages

## Testing

To test the return URL flow:

1. Set up your app with a custom URL scheme (e.g., `mytestapp://`)
2. Use Klarna's playground environment
3. During the payment flow, the Klarna SDK may redirect to external apps
4. After completing the external flow, your app should automatically reopen

## Additional Resources

- [Klarna Mobile SDK Documentation](https://docs.klarna.com/payments/mobile-payments/)
- [Klarna Express Checkout Guide](https://docs.klarna.com/express-checkout/)
- [Flutter Platform Views](https://docs.flutter.dev/platform-integration/platform-views)

## Need Help?

If you encounter issues:

1. Check the error messages in Xcode console
2. Verify all configuration steps are completed
3. Try cleaning and rebuilding the project
4. Check that you're using compatible SDK versions
