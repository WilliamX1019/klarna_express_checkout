/// Shipping address data
class ShippingAddress {
  final String? givenName;
  final String? familyName;
  final String? email;
  final String? streetAddress;
  final String? city;
  final String? postalCode;
  final String? region;
  final String? country;
  final String? phone;

  ShippingAddress({
    this.givenName,
    this.familyName,
    this.email,
    this.streetAddress,
    this.city,
    this.postalCode,
    this.region,
    this.country,
    this.phone,
  });

  factory ShippingAddress.fromMap(Map<dynamic, dynamic> map) {
    return ShippingAddress(
      givenName: map['givenName'] as String?,
      familyName: map['familyName'] as String?,
      email: map['email'] as String?,
      streetAddress: map['streetAddress'] as String?,
      city: map['city'] as String?,
      postalCode: map['postalCode'] as String?,
      region: map['region'] as String?,
      country: map['country'] as String?,
      phone: map['phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (givenName != null) 'givenName': givenName,
      if (familyName != null) 'familyName': familyName,
      if (email != null) 'email': email,
      if (streetAddress != null) 'streetAddress': streetAddress,
      if (city != null) 'city': city,
      if (postalCode != null) 'postalCode': postalCode,
      if (region != null) 'region': region,
      if (country != null) 'country': country,
      if (phone != null) 'phone': phone,
    };
  }
}

/// Authorization result returned after successful authorization
class AuthorizationResult {
  final String? authorizationToken;
  final String? clientToken;
  final String? sessionId;
  final ShippingAddress? shippingAddress;
  final bool? approved;
  final bool? finalizedRequired;

  AuthorizationResult({
    this.authorizationToken,
    this.clientToken,
    this.sessionId,
    this.shippingAddress,
    this.approved,
    this.finalizedRequired,
  });

  factory AuthorizationResult.fromMap(Map<dynamic, dynamic> map) {
    return AuthorizationResult(
      authorizationToken: map['authorizationToken'] as String? ?? '',
      clientToken: map['clientToken'] as String? ?? '',  
      sessionId: map['sessionId'] as String? ?? '',
      shippingAddress: map['shippingAddress'] != null
          ? ShippingAddress.fromMap(map['shippingAddress'] as Map)
          : null,
      approved: map['approved'] as bool? ?? false,
      finalizedRequired: map['finalizedRequired'] as bool? ?? false,
    );
  }

  @override
  String toString() {
    return 'AuthorizationResult(authorizationToken: $authorizationToken, sessionId: $sessionId, shippingAddress: $shippingAddress, approved: $approved, finalizedRequired: $finalizedRequired)';
  }
}
