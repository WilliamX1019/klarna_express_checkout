# Android Setup Guide for Klarna Express Checkout

This guide covers the Android-specific setup required for the Klarna Express Checkout Flutter plugin.

## Prerequisites

- Android SDK 21 (Lollipop) or higher
- Kotlin support enabled
- Gradle 7.0+

## Required Android Configuration

### 1. Add Klarna Maven Repository

Add the Klarna Maven repository to your project. Open `android/build.gradle` and add:

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url "https://x.klarnacdn.net/mobile-sdk/"
        }
    }
}
```

**Note**: If your project uses the newer `settings.gradle` approach (Gradle 7+), add the repository there instead:

```gradle
dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
        maven {
            url "https://x.klarnacdn.net/mobile-sdk/"
        }
    }
}
```

### 2. SDK Dependency

The Klarna Mobile SDK dependency is automatically included by the plugin. You can verify it in the plugin's `android/build.gradle`:

```gradle
dependencies {
    implementation 'com.klarna.mobile:sdk:2.x.x'
}
```

### 3. Internet Permission

Ensure your app has internet permission. This should already be in your `android/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

### 4. ProGuard Rules (if using code shrinking)

If you're using ProGuard or R8 for code shrinking, add these rules to `android/app/proguard-rules.pro`:

```proguard
# Klarna Mobile SDK
-keep class com.klarna.** { *; }
-dontwarn com.klarna.**
```

## Button Configuration

### Basic Configuration

```dart
KlarnaExpressCheckoutButton(
  clientToken: 'your_client_token',  // Server-side session
  // OR
  clientId: 'your_client_id',        // Client-side session

  returnUrl: 'yourapp://',           // Your app's custom URL scheme
  environment: KlarnaEnvironment.playground,
  region: 'na',                      // 'na', 'eu', or 'oc'
  locale: 'en-US',

  onAuthorized: (response) {
    print('Authorized: ${response.authorizationToken}');
  },
  onError: (error) {
    print('Error: ${error.message}');
  },
)
```

### Advanced Styling

Android supports additional styling options:

```dart
KlarnaExpressCheckoutButton(
  theme: 'dark',  // 'dark', 'light', or 'auto'
  styleConfiguration: {
    'shape': 'rounded_rect',  // 'rectangle', 'rounded_rect', or 'pill'
    'style': 'filled',        // 'filled' or 'outlined'
  },
  // ... other options
)
```

#### Available Style Options:

**Themes:**
- `dark` - Dark theme (default)
- `light` - Light theme
- `auto` - Automatically adapts to system theme

**Shapes:**
- `rectangle` - Sharp corners
- `rounded_rect` - Rounded corners (default)
- `pill` - Fully rounded (pill-shaped)

**Styles:**
- `filled` - Solid button (default)
- `outlined` - Outline button

### Logging Configuration

Enable verbose logging for debugging:

```dart
KlarnaExpressCheckoutButton(
  loggingLevel: 'verbose',  // 'off', 'error', or 'verbose'
  // ... other options
)
```

Check logs using `adb logcat` or Android Studio Logcat:
```bash
adb logcat | grep Klarna
```

## Session Types

### Server-Side Session (Recommended)

Generate a client token on your backend and pass it to the button:

```dart
KlarnaExpressCheckoutButton(
  sessionType: 'serverSide',
  clientToken: await fetchClientTokenFromBackend(),
  returnUrl: 'yourapp://',
  // ... other options
)
```

### Client-Side Session

Use your client ID from the Klarna Merchant Portal:

```dart
KlarnaExpressCheckoutButton(
  sessionType: 'clientSide',
  clientId: 'your_client_id',
  amount: 99.99,
  currency: 'USD',
  returnUrl: 'yourapp://',
  collectShippingAddress: true,
  // ... other options
)
```

## Deep Link Handling

### Configure Custom URL Scheme

Add to `android/src/main/AndroidManifest.xml` inside your main `<activity>`:

```xml
<activity
    android:name=".MainActivity"
    ...>

    <!-- Existing intent filters -->
    <intent-filter>
        <action android:name="android.intent.action.MAIN"/>
        <category android:name="android.intent.category.LAUNCHER"/>
    </intent-filter>

    <!-- Add this for Klarna deep linking -->
    <intent-filter android:autoVerify="true">
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data
            android:scheme="yourapp"
            android:host="klarna" />
    </intent-filter>
</activity>
```

Replace `yourapp` with your app's unique URL scheme.

### Handle Deep Links in Flutter

```dart
void initState() {
  super.initState();

  // Listen for deep link events
  _linkSubscription = getUriLinksStream().listen((Uri? uri) {
    if (uri != null && uri.scheme == 'yourapp') {
      // Klarna SDK automatically handles the return
      print('Returned from external app: $uri');
    }
  });
}
```

## Error Handling

Handle different error types:

```dart
KlarnaExpressCheckoutButton(
  onError: (error) {
    switch (error.code) {
      case 'invalidClientId':
        print('Invalid client ID provided');
        break;
      case 'authorizationFailed':
        print('User authorization failed');
        break;
      case 'networkError':
        print('Network connection issue');
        break;
      case 'sessionError':
        print('Session expired or invalid');
        break;
      default:
        print('Error: ${error.message}');
    }
  },
)
```

### Common Error Codes:

- `invalidClientId` - Client ID is null or invalid
- `authorizationFailed` - Payment authorization failed
- `alreadyInProgress` - Checkout flow already active
- `buttonRenderFailed` - Button rendering failed
- `networkError` - Network connection issue
- `sessionError` - Session expired or invalid
- `tokenError` - Token-related error
- `cancelled` - User cancelled the flow

## Testing

### Test Mode Configuration

Use playground environment for testing:

```dart
KlarnaExpressCheckoutButton(
  environment: KlarnaEnvironment.playground,
  // ... other options
)
```

### Test Credentials

Use test credentials from your Klarna Merchant Portal for the playground environment.

### Debugging

1. Enable verbose logging:
   ```dart
   loggingLevel: 'verbose'
   ```

2. Check Android Studio Logcat:
   ```bash
   adb logcat | grep -i klarna
   ```

3. Verify button configuration:
   ```dart
   onError: (error) {
     print('Config Error: ${error.code} - ${error.message}');
   }
   ```

## SDK Version Requirements

- Klarna requires partners to update to the latest SDK version at least once every 3 months
- Only SDK versions released within the last 6 months are officially supported
- The plugin automatically uses a compatible SDK version

## Best Practices

1. **Always use server-side sessions in production** for better security
2. **Implement proper error handling** for all error types
3. **Test thoroughly** in playground environment before going live
4. **Keep the SDK updated** according to Klarna's versioning policy
5. **Don't modify cart contents** after authorization
6. **Create orders within 60 minutes** of receiving the authorization token

## Common Issues

### Issue: Button doesn't appear

**Solution**:
1. Check that you've provided valid `clientToken` or `clientId`
2. Verify the environment setting
3. Check Logcat for error messages
4. Ensure Maven repository is correctly configured

### Issue: "Button already in progress" error

**Solution**:
- Only one authorization flow can be active at a time
- Wait for the current flow to complete before starting another

### Issue: Deep link doesn't return to app

**Solution**:
1. Verify custom URL scheme in `AndroidManifest.xml`
2. Ensure the `returnUrl` matches your URL scheme
3. Check that the scheme is unique and not used by other apps

### Issue: Build fails with "Cannot resolve klarna dependency"

**Solution**:
1. Verify Maven repository URL in `build.gradle`
2. Run `flutter clean`
3. Run `cd android && ./gradlew clean`
4. Rebuild the project

## Additional Resources

- [Klarna Android SDK Documentation](https://docs.klarna.com/conversion-boosters/express-checkout/integrate-express-checkout/mobile-sdk-integration/android/)
- [Klarna Mobile SDK Guidelines](https://docs.klarna.com/payments/mobile-payments/before-you-start/mobile-sdk-guidelines/)
- [Klarna Merchant Portal](https://portal.klarna.com/)

## Need Help?

If you encounter issues:

1. Check error messages in Logcat
2. Verify all configuration steps are completed
3. Try cleaning and rebuilding the project
4. Check that you're using compatible versions
5. Contact Klarna support for API-specific issues
