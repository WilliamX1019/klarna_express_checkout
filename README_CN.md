# Klarna Express Checkout Flutter Plugin

一个用于在iOS和Android平台上集成Klarna Express Checkout的Flutter插件。该插件封装了原生的Klarna Mobile SDK，为Flutter应用提供无缝的快速结账体验。

## 📱 平台支持状态

- ✅ **iOS**: 完整实现，已测试
- ⚠️ **Android**: 基础框架已完成，但Klarna Express Checkout Android API文档尚不完整

  > **Android注意事项**: Klarna在2.7.0版本中添加了Express Checkout支持，但官方文档中Express Checkout Button的具体API类和包名尚未完全公开。Android端实现目前显示占位符。我们正在等待Klarna提供更详细的Android SDK文档。

## 功能特性

- ✅ 支持iOS和Android平台（iOS完整可用）
- ✅ 客户端和服务端会话管理
- ✅ 可自定义按钮样式（主题、形状、样式）
- ✅ 完整的授权流程处理
- ✅ 收货地址收集
- ✅ 生产环境和沙盒环境支持
- ✅ 完善的错误处理机制

## 前置要求

在使用此插件之前，您需要：

1. 拥有Klarna商户账户并配置了Payments/Checkout集成
2. 客户端凭证（客户端模式需要Client ID，服务端模式需要后端生成token）
3. 在Klarna商户门户中将域名URL加入白名单
4. iOS端：配置自定义URL Scheme用于返回导航

## 安装

在您的 `pubspec.yaml` 文件中添加：

```yaml
dependencies:
  klarna_express_checkout:
    git:
      url: https://github.com/yourusername/klarna_express_checkout.git
```

### iOS配置

1. Klarna Mobile SDK会通过插件自动添加到Podfile

2. 在 `Info.plist` 中配置自定义URL Scheme：

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>myapp</string>
        </array>
    </dict>
</array>
```

3. 在 `Info.plist` 中添加App Queries：

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>klarna</string>
    <string>klarnaconsent</string>
</array>
```

4. 在 `AppDelegate.swift` 中处理返回URL：

```swift
override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
    return KlarnaMobileSDK.shared.handleDeeplink(url: url)
}
```

### Android配置

1. **添加Klarna Maven仓库**到项目的 `android/build.gradle`：

```gradle
allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url 'https://x.klarnacdn.net/mobile-sdk/' }
    }
}
```

> **注意**: 此仓库是下载Klarna Mobile SDK所必需的。插件的`build.gradle`中已包含此配置，但您可能也需要将其添加到主项目中。

2. 确保 `android/app/build.gradle` 中的最小SDK版本：

```gradle
android {
    defaultConfig {
        minSdkVersion 21
    }
}
```

3. **Android Express Checkout状态**:
   - Android端的基础架构已就绪
   - Klarna Express Checkout Button的具体API尚待官方文档完善
   - 目前会显示开发中的占位符
   - 建议关注[Klarna Android SDK文档](https://docs.klarna.com/conversion-boosters/express-checkout/integrate-express-checkout/mobile-sdk-integration/android/)更新

## 使用方法

### 基础实现

```dart
import 'package:flutter/material.dart';
import 'package:klarna_express_checkout/klarna_express_checkout.dart';

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Checkout')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: KlarnaExpressCheckoutButton(
          config: KlarnaExpressCheckoutConfig(
            sessionConfig: KlarnaClientSideSession(
              clientId: 'YOUR_CLIENT_ID',
              locale: 'en-US',
              amount: 50.00,
              currency: 'USD',
            ),
            buttonConfig: KlarnaButtonConfig(
              theme: KlarnaTheme.dark,
              shape: KlarnaButtonShape.roundedRect,
              style: KlarnaButtonStyle.filled,
            ),
            environment: KlarnaEnvironment.sandbox,
            returnUrl: 'myapp://klarna/return', // 仅iOS需要
          ),
          onAuthorized: (result) {
            print('授权成功: ${result.authorizationToken}');
            // 将token发送到后端创建订单
          },
          onError: (error) {
            print('错误: ${error.message}');
          },
          height: 50.0,
        ),
      ),
    );
  }
}
```

### 客户端会话

客户端会话允许您直接在应用中管理会话数据：

```dart
KlarnaExpressCheckoutButton(
  config: KlarnaExpressCheckoutConfig(
    sessionConfig: KlarnaClientSideSession(
      clientId: 'YOUR_CLIENT_ID',
      locale: 'en-US',
      amount: 99.99,
      currency: 'USD',
      email: 'customer@example.com', // 可选
      phoneNumber: '+1234567890', // 可选
    ),
    environment: KlarnaEnvironment.production,
  ),
  onAuthorized: _handleAuthorization,
  onError: _handleError,
)
```

### 服务端会话

服务端会话更安全，将敏感数据保留在后端：

```dart
// 1. 从后端获取客户端token
Future<String> getClientToken() async {
  final response = await http.post(
    Uri.parse('https://your-backend.com/create-klarna-session'),
    body: jsonEncode({
      'amount': 5000, // 单位为分(cents)
      'currency': 'USD',
    }),
  );
  return jsonDecode(response.body)['client_token'];
}

// 2. 使用token创建按钮
FutureBuilder<String>(
  future: getClientToken(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return CircularProgressIndicator();
    }

    return KlarnaExpressCheckoutButton(
      config: KlarnaExpressCheckoutConfig(
        sessionConfig: KlarnaServerSideSession(
          clientToken: snapshot.data!,
          locale: 'en-US',
        ),
      ),
      onAuthorized: _handleAuthorization,
      onError: _handleError,
    );
  },
)
```

### 处理授权

当用户完成授权后，将token发送到您的后端：

```dart
void _handleAuthorization(AuthorizationResult result) async {
  // 授权token有效期为60分钟
  final token = result.authorizationToken;
  final sessionId = result.sessionId;

  // 收货地址（如果收集）
  final shippingAddress = result.shippingAddress;

  // 发送到后端创建订单
  final response = await http.post(
    Uri.parse('https://your-backend.com/create-order'),
    body: jsonEncode({
      'authorization_token': token,
      'session_id': sessionId,
    }),
  );

  if (response.statusCode == 200) {
    final orderId = jsonDecode(response.body)['order_id'];
    // 导航到确认页面
  }
}
```

### 后端订单创建

您的后端需要使用授权token创建订单：

```javascript
// Node.js后端示例
app.post('/create-order', async (req, res) => {
  const { authorization_token } = req.body;

  const response = await fetch(
    `https://api.klarna.com/payments/v1/authorizations/${authorization_token}/order`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Basic ${Buffer.from(
          `${KLARNA_USERNAME}:${KLARNA_PASSWORD}`
        ).toString('base64')}`,
      },
      body: JSON.stringify({
        purchase_country: 'US',
        purchase_currency: 'USD',
        locale: 'en-US',
        order_amount: 5000,
        order_lines: [
          {
            name: 'Product Name',
            quantity: 1,
            unit_price: 5000,
            total_amount: 5000,
          },
        ],
        merchant_urls: {
          confirmation: 'https://your-site.com/confirmation',
        },
      }),
    }
  );

  const order = await response.json();
  res.json({
    order_id: order.order_id,
    redirect_url: order.redirect_url,
  });
});
```

## 配置选项

### 按钮样式

```dart
KlarnaButtonConfig(
  theme: KlarnaTheme.dark,      // dark, light, auto
  shape: KlarnaButtonShape.roundedRect, // roundedRect, pill, rectangle
  style: KlarnaButtonStyle.filled,      // filled, outlined
)
```

### 环境

```dart
environment: KlarnaEnvironment.sandbox,    // 测试环境
environment: KlarnaEnvironment.production, // 生产环境
```

### 语言区域

支持的语言区域包括：
- `en-US`, `en-GB`, `en-AU`
- `de-DE`, `de-AT`, `de-CH`
- `fr-FR`, `fr-BE`, `fr-CH`
- `es-ES`, `it-IT`, `nl-NL`
- `sv-SE`, `no-NO`, `fi-FI`, `da-DK`
- 等等...

## 错误处理

插件提供详细的错误信息：

```dart
void _handleError(KlarnaError error) {
  switch (error.code) {
    case KlarnaErrorCode.cancelled:
      // 用户取消了流程
      break;
    case KlarnaErrorCode.invalidConfiguration:
      // 检查您的配置
      break;
    case KlarnaErrorCode.networkError:
      // 网络问题
      break;
    case KlarnaErrorCode.authorizationFailed:
      // 授权失败
      break;
    case KlarnaErrorCode.sessionExpired:
      // 会话过期
      break;
    case KlarnaErrorCode.unknown:
      // 未知错误
      break;
  }

  print('错误: ${error.message}');
  if (error.isFatal) {
    // 处理致命错误
  }
}
```

## API参考

### KlarnaExpressCheckoutButton

显示Klarna Express Checkout按钮的主要Widget。

**属性:**
- `config`: `KlarnaExpressCheckoutConfig` - 按钮配置
- `onAuthorized`: `Function(AuthorizationResult)` - 成功回调
- `onError`: `Function(KlarnaError)` - 错误回调
- `width`: `double?` - 按钮宽度（默认为父容器宽度）
- `height`: `double` - 按钮高度（默认50.0）

### AuthorizationResult

包含授权数据：
- `authorizationToken`: `String` - 创建订单的token（有效期60分钟）
- `sessionId`: `String` - 会话标识符
- `shippingAddress`: `ShippingAddress?` - 收货地址（如果收集）
- `approved`: `bool` - 授权是否通过
- `finalizedAt`: `String?` - 完成时间戳

## 测试

使用 `KlarnaEnvironment.sandbox` 和Klarna的测试凭证进行测试。

## 故障排除

### iOS问题

- **按钮不显示**: 确保已配置返回URL scheme
- **深链接不工作**: 检查 `Info.plist` 和 `AppDelegate.swift` 配置

### Android问题

- **构建错误**: 验证minSdkVersion至少为21
- **Maven仓库错误**: 确保在build.gradle中添加了 `https://x.klarnacdn.net/mobile-sdk/` 仓库
- **按钮显示占位符**: Android Express Checkout API尚在完善中，请关注Klarna官方文档更新

## 已知限制

1. **Android Express Checkout**: Klarna Mobile SDK的Android Express Checkout Button API文档尚不完整。虽然功能在SDK v2.7.0中引入，但具体的包名和类名尚未在公开文档中详细说明。

2. **SDK版本要求**: Klarna要求所有合作伙伴至少每3个月更新一次SDK版本，仅支持过去6个月内发布的SDK版本。

3. **授权token有效期**: 授权token有效期为60分钟，需要及时发送到后端创建订单。

## 资源

- 插件问题：[GitHub Issues](https://github.com/yourusername/klarna_express_checkout/issues)
- Klarna API：[Klarna文档](https://docs.klarna.com)
- iOS集成：[iOS SDK文档](https://docs.klarna.com/conversion-boosters/express-checkout/integrate-express-checkout/mobile-sdk-integration/ios/)
- Android集成：[Android SDK文档](https://docs.klarna.com/conversion-boosters/express-checkout/integrate-express-checkout/mobile-sdk-integration/android/)
- Klarna Mobile SDK：
  - [iOS SDK GitHub](https://github.com/klarna/klarna-mobile-sdk-ios)
  - [Android SDK GitHub](https://github.com/klarna/klarna-mobile-sdk-android)

## 许可证

本项目采用MIT许可证。

## 贡献

欢迎贡献！在提交PR之前请阅读贡献指南。

## 更新日志

### v0.1.0
- ✅ iOS端完整实现
- ✅ Android端基础框架
- ✅ 客户端和服务端会话支持
- ✅ 完整的Flutter Dart API
- ⚠️ Android Express Checkout Button待官方API文档完善
