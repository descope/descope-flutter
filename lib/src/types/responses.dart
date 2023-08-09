import 'dart:typed_data';

import '/src/session/token.dart';
import '/src/types/user.dart';

/// Returned from user authentication calls.
class AuthenticationResponse {
  /// The user's session token is used to perform authorized backend requests.
  final DescopeToken sessionToken;

  /// The refresh token is used to refresh expired session tokens.
  final DescopeToken refreshToken;

  /// Whether this the user's first authentication.
  final bool isFirstAuthentication;

  /// Information about the user.
  final DescopeUser user;

  AuthenticationResponse(this.sessionToken, this.refreshToken, this.isFirstAuthentication, this.user);
}

/// Returned from the refreshSession call.
///
/// The refresh token might get updated as well with new information on the user that
/// might have changed.
class RefreshResponse {
  /// Refreshed session token
  final DescopeToken sessionToken;

  /// Optionally a refresh token
  final DescopeToken? refreshToken;

  RefreshResponse(this.sessionToken, this.refreshToken);
}

/// Returned from calls that start an enchanted link flow.
///
/// The [linkId] value needs to be displayed to the user so they know which
/// link should be clicked on in the enchanted link email. The [maskedEmail]
/// field can also be shown to inform the user to which address the email
/// was sent. The [pendingRef] field is used to poll the server for the
/// enchanted link flow result.
class EnchantedLinkResponse {
  final String linkId;
  final String pendingRef;
  final String maskedEmail;

  EnchantedLinkResponse(this.linkId, this.pendingRef, this.maskedEmail);
}

/// Returned from TOTP calls that create a new seed.
///
/// The [provisioningUrl] field wraps the key (seed) in a URL that can be
/// opened by authenticator apps. The [image] field encodes the key (seed)
/// in a QR code image.
class TotpResponse {
  final String provisioningUrl;
  final Uint8List image;
  final String key;

  TotpResponse(this.provisioningUrl, this.image, this.key);
}

/// Represents the rules for valid passwords.
///
/// The policy is configured in the password settings in the Descope console, and
/// these values can be used to implement client-side validation of new user passwords
/// for a better user experience.
///
/// In any case, all password rules are enforced by Descope on the server side as well.
class PasswordPolicy {
  final int minLength;
  final bool lowercase;
  final bool uppercase;
  final bool number;
  final bool nonAlphanumeric;

  PasswordPolicy(this.minLength, this.lowercase, this.uppercase, this.number, this.nonAlphanumeric);
}
