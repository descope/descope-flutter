import 'dart:convert';
import 'dart:typed_data';

import '/src/internal/others/error.dart';

/// A [DescopeToken] is a utility wrapper around a single JWT value.
///
/// The session and refresh JWTs in a [DescopeSession] are stored as
/// instances of [DescopeToken]. It's also returned directly when
/// exchanging an access key for a session JWT.
abstract class DescopeToken {
  /// The underlying JWT value
  String get jwt;

  /// The value of the "sub" (subject) claim, which is the unique id
  /// of the user or access key the JWT was generated for.
  String get id;

  /// The value of the "iss" (issuer) claim which is the unique id
  /// of the Descope project the JWT was generated for.
  String get projectId;

  /// The value of the "exp" (expiration time) claim which is the time
  /// after which the JWT expires.
  DateTime? get expiresAt;

  /// Whether the JWT expiry time (if any) has already passed.
  bool get isExpired;

  /// A map with all the custom claims in the JWT value. It includes
  /// any claims whose values aren't already exposed by other accessors
  /// or authorization functions.
  Map<String, dynamic> get customClaims;

  /// Returns the list of permissions granted in the JWT claims. Pass
  /// a value of `null` for the [tenant] parameter if the project
  /// doesn't use multiple tenants.
  List<String> getPermissions({required String? tenant});

  /// Returns the list of roles granted in the JWT claims. Pass
  /// a value of `null` for the [tenant] parameter if the project
  /// doesn't use multiple tenants.
  List<String> getRoles({required String? tenant});
}

// Internal

class Token implements DescopeToken {
  @override
  final String jwt;

  @override
  final String id;

  @override
  final String projectId;

  @override
  final Map<String, dynamic> customClaims;

  final Map<String, dynamic> allClaims;

  @override
  final DateTime? expiresAt;

  @override
  bool get isExpired {
    return expiresAt?.isBefore(DateTime.now()) ?? false;
  }

  @override
  List<String> getPermissions({required String? tenant}) {
    try {
      final items = Claim.permissions.getTypedTenantValue<List<dynamic>>(allClaims, tenant);
      return items.cast<String>().toList();
    } catch (e) {
      return <String>[];
    }
  }

  @override
  List<String> getRoles({required String? tenant}) {
    try {
      final items = Claim.roles.getTypedTenantValue<List<dynamic>>(allClaims, tenant);
      return items.cast<String>().toList();
    } catch (e) {
      return <String>[];
    }
  }

  Token(this.jwt, this.id, this.projectId, this.expiresAt, this.customClaims, this.allClaims);

  factory Token.decode(String jwt) {
    final claims = decodeJWT(jwt);
    final id = Claim.subject.getTypedValue<String>(claims);
    final projectId = decoderIssuer(Claim.issuer.getTypedValue<String>(claims));
    final expiration = Claim.expiration.getTypedValue<int>(claims);
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(expiration * 1000, isUtc: true);
    final customClaims = claims.filterPrivateClaims();
    return Token(jwt, id, projectId, expiresAt, customClaims, claims);
  }

  @override
  String toString() {
    var expires = 'expires: Never';
    if (expiresAt != null) {
      final label = isExpired ? 'expired' : 'expires';
      expires = '$label: $expiresAt';
    }
    return 'DescopeToken(id: $id, $expires)';
  }
}

// Claims

enum Claim {
  audience('aud'),
  subject('sub'),
  issuer('iss'),
  issuedAt('iat'),
  expiration('exp'),
  tenants('tenants'),
  permissions('permissions'),
  roles('roles');

  final String key;

  const Claim(this.key);

  static bool isPrivateClaim(String key) {
    return Claim.values.any((element) => element.key == key);
  }

  T getTypedValue<T>(Map<String, dynamic> claims) {
    final object = claims[key];
    if (object == null) {
      throw InternalErrors.decodeError.add(message: "Missing $key claim in token");
    }
    if (object is T) {
      return object;
    }
    throw InternalErrors.decodeError.add(message: "Invalid $key claim in token");
  }

  T getTypedTenantValue<T>(Map<String, dynamic> claims, String? tenant) {
    if (tenant != null) {
      return getTenantValue<T>(claims, key, tenant);
    }
    return getTypedValue<T>(claims);
  }
}

extension on Map<String, dynamic> {
  Map<String, dynamic> filterPrivateClaims() {
    Map<String, dynamic> result = {};
    forEach((key, value) {
      if (!Claim.isPrivateClaim(key)) {
        result[key] = value;
      }
    });
    return result;
  }
}

// Authorization

T getTenantValue<T>(Map<String, dynamic> claims, String key, String tenant) {
  final info = getTenant(claims, tenant);
  final value = info[key];
  if (value is T) {
    return value;
  }
  throw InternalErrors.decodeError.add(message: invalidTenant(tenant));
}

Map<String, dynamic> getTenant(Map<String, dynamic> claims, String tenant) {
  final tenants = getTenants(claims);
  final object = tenants[tenant];
  if (object == null) {
    throw InternalErrors.decodeError.add(message: "Tenant $tenant not found in token");
  }
  if (object is Map<String, dynamic>) {
    return object;
  }
  throw InternalErrors.decodeError.add(message: invalidTenant(tenant));
}

Map<String, dynamic> getTenants(Map<String, dynamic> claims) {
  return Claim.tenants.getTypedValue<Map<String, dynamic>>(claims);
}

// JWT Decoding

Uint8List decodeEncodedFragment(String value) {
  final length = 4 * ((value.length + 3) / 4).floor();
  try {
    final data = const Base64Decoder().convert(value.padRight(length, '='));
    return data;
  } catch (e) {
    throw InternalErrors.decodeError.add(message: invalidEncoding(), cause: e);
  }
}

Map<String, dynamic> decodeFragment(String value) {
  final data = decodeEncodedFragment(value);
  dynamic cause, json;
  try {
    final string = utf8.decode(data);
    try {
      json = jsonDecode(string);
    } catch (e) {
      throw InternalErrors.decodeError.add(message: 'Invalid token data', cause: e);
    }
    if (json is Map<String, dynamic>) {
      return json;
    }
  } catch (e) {
    cause = e;
  }
  throw InternalErrors.decodeError.add(message: invalidEncoding(), cause: cause);
}

Map<String, dynamic> decodeJWT(String jwt) {
  final fragments = jwt.split('.');
  if (fragments.length != 3) {
    throw InternalErrors.decodeError.add(message: 'Invalid token format');
  }
  return decodeFragment(fragments[1]);
}

String decoderIssuer(String issuer) {
  final parts = issuer.split('/');
  return parts.isEmpty ? issuer : parts.last;
}

// errors

String invalidEncoding() => 'Invalid token encoding';

String invalidTenant(String tenant) => "Invalid data for tenant $tenant in token";
