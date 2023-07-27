
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
class SignUpDetails {
  final String? name;
  final String? email;
  final String? phone;

  SignUpDetails({this.name, this.email, this.phone});
}
