import 'package:flutter/material.dart';
import 'package:klarna_express_checkout/klarna_express_checkout.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Klarna Express Checkout Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CheckoutPage(),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({Key? key}) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  bool _isLoading = false;
  String _statusMessage = '';

  // Example configuration - replace with your actual values
  static const String clientId = 'klarna_test_client_dk4tcW85NzAlcHhER3MxVXhnNGxaQkR0WVMtdzFIdEwsMjI2ZDJhZGEtMzU3ZC00OWE0LWI2NGItODJmN2FmMDEyMGNlLDEsYmdrYUVpYWgrU014a2pBMlVsaFdvWTEzZExHRTRCSXA0THVDVVY5YlM5QT0';
  static const String backendUrl = 'com.unice.longqihair://klarnaLogin';

  // Example 1: Client-side session
  void _handleClientSideCheckout() {
    setState(() {
      _statusMessage = 'Initializing client-side checkout...';
    });
  }

  // Example 2: Server-side session
  Future<String?> _getClientToken() async {
    try {
      // Call your backend to get a client token
      final response = await http.post(
        Uri.parse('$backendUrl/create-klarna-session'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': 5000, // $50.00
          'currency': 'USD',
          'locale': 'en-US',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['client_token'];
      }
    } catch (e) {
      print('Error getting client token: $e');
    }
    return null;
  }

  void _onAuthorized(AuthorizationResult result) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Processing authorization...';
    });

    print('Authorization successful!');
    print('Token: ${result.authorizationToken}');
    print('Session ID: ${result.sessionId}');

    // Send the authorization token to your backend to create the order
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/create-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'authorization_token': result.authorizationToken,
          'session_id': result.sessionId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orderId = data['order_id'];
        final redirectUrl = data['redirect_url'];

        setState(() {
          _isLoading = false;
          _statusMessage = 'Order created successfully! Order ID: $orderId';
        });

        // Show success dialog
        _showSuccessDialog(orderId);
      } else {
        throw Exception('Failed to create order');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });

      _showErrorDialog('Failed to create order: $e');
    }
  }

  void _onError(KlarnaError error) {
    setState(() {
      _statusMessage = 'Error: ${error.message}';
    });

    print('Klarna error: ${error.toString()}');

    if (error.code != KlarnaErrorCode.cancelled) {
      _showErrorDialog(error.message);
    }
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Created'),
        content: Text('Your order has been created successfully!\n\nOrder ID: $orderId'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Klarna Express Checkout'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Product info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sample Product',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A great product that you will love',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '\$50.00',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Client-side session example
            const Text(
              'Client-side Session Example:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              height: 50,
              width: 60,
              color: Colors.orange,
              child: KlarnaExpressCheckoutButton(
                width: 60,
                config: KlarnaExpressCheckoutConfig(
                  sessionConfig: KlarnaClientSideSession(
                    clientId: clientId,
                    locale: 'en-US',
                    amount: 50.00,
                    currency: 'USD',
                  ),
                  buttonConfig: const KlarnaButtonConfig(
                    theme: KlarnaTheme.light,
                    shape: KlarnaButtonShape.roundedRect,
                    style: KlarnaButtonStyle.filled,
                  ),
                  environment: KlarnaEnvironment.sandbox,
                  returnUrl: 'myapp://klarna/return', // iOS only
                ),
                onAuthorized: _onAuthorized,
                onError: _onError,
              ),
            ),

            const SizedBox(height: 24),

            // Server-side session example (commented out)
            const Text(
              'Server-side Session Example:',
              style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red),
            ),
            const Text(
              '(Uncomment the code below and provide a backend)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),

            /*
            FutureBuilder<String?>(
              future: _getClientToken(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 50,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const SizedBox(
                    height: 50,
                    child: Center(
                      child: Text('Failed to load client token'),
                    ),
                  );
                }

                return SizedBox(
                  height: 50,
                  child: KlarnaExpressCheckoutButton(
                    config: KlarnaExpressCheckoutConfig(
                      sessionConfig: KlarnaServerSideSession(
                        clientToken: snapshot.data!,
                        locale: 'en-US',
                      ),
                      buttonConfig: const KlarnaButtonConfig(
                        theme: KlarnaTheme.light,
                        shape: KlarnaButtonShape.pill,
                        style: KlarnaButtonStyle.outlined,
                      ),
                      environment: KlarnaEnvironment.sandbox,
                    ),
                    onAuthorized: _onAuthorized,
                    onError: _onError,
                  ),
                );
              },
            ),
            */

            const SizedBox(height: 24),

            // Status message
            if (_statusMessage.isNotEmpty)
              Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(right: 12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _statusMessage,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
