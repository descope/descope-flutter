import 'dart:typed_data';

// Enums

/// The delivery method for an OTP or Magic Link message.
enum DeliveryMethod {
  email,
  sms,
  whatsapp,
}

/// The provider to use in an OAuth flow.
enum OAuthProvider {
  facebook,
  github,
  google,
  microsoft,
  gitlab,
  apple,
}

// Classes

/// Used to provide additional details about a user in sign up calls.
class User {
  final String? name;
  final String? email;
  final String? phone;

  User({this.name, this.email, this.phone});
}

// Responses

/// Returned from the me call.
///
/// The [userId] field is the unique identifier for the user in Descope, and it
/// matches the `Subject` (`sub`) value in the user's `JWT` after logging in. The
/// [loginIds] is the set of acceptable login identifiers for the user, e.g.,
/// email addresses, phone numbers, usernames, etc.
class MeResponse {
  final String userId;
  final List<String> loginIds;
  final String? name;
  final String? picture;
  final String? email;
  final bool isEmailVerified;
  final String? phone;
  final bool isPhoneVerified;

  MeResponse(this.userId, this.loginIds, this.name, this.picture, this.email, this.isEmailVerified, this.phone, this.isPhoneVerified);
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
