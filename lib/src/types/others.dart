
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

/// Used to provide additional details about a user in sign up calls.
class SignUpDetails {
  final String? name;
  final String? email;
  final String? phone;

  SignUpDetails({this.name, this.email, this.phone});
}

/// Used to require additional behaviors when authenticating a user.
class SignInOptions {
  /// Used to add layered security to your app by implementing Step-up authentication.
  ///
  ///     final session = Descope.sessionManager.session;
  ///     if (session == null) {
  ///         throw Exception('User is not logged in');
  ///     }
  ///     final options = SignInOptions(stepupRefreshJwt: session.refreshJwt);
  ///     final future = Descope.otp.signIn(method: DeliveryMethod.email, loginId: email, options: options);
  ///
  /// After the Step-up authentication completes successfully the returned session JWT will
  /// have an `su` claim with a value of `true`.
  ///
  /// **Note:** The `su` claim is not set on the refresh JWT.
  final String? stepupRefreshJwt;

  /// Used to add layered security to your app by implementing Multi-factor authentication.
  ///
  /// Assuming the user has already signed in successfully with one authentication method,
  /// we can take the `refreshJwt` from the [AuthenticationResponse] and pass it as the
  /// [mfaRefreshJwt] value to another authentication method.
  ///
  ///     final options = SignInOptions(mfaRefreshJwt: authResponse.refreshJwt);
  ///     final future = Descope.otp.signIn(method: DeliveryMethod.email, loginId: email, options: options);
  ///
  /// After the MFA authentication completes successfully the `amr` claim in both the session
  /// and refresh JWTs will be an array with an entry for each authentication method used.
  final String? mfaRefreshJwt;

  /// Adds additional custom claims to the user's JWT during authentication.
  ///
  /// For example, the following code starts an OTP sign in and requests a custom claim
  /// with the authenticated user's full name:
  ///
  ///     const options = SignInOptions(customClaims: {"name": "{{user.name}}"});
  ///     await Descope.otp.signIn(method: DeliveryMethod.email, loginId: email, options: options);
  ///
  /// **Important:** Any custom claims added via this method are considered insecure and will
  /// be nested under the `nsec` custom claim.
  final Map<String, dynamic> customClaims;

  const SignInOptions({this.stepupRefreshJwt, this.mfaRefreshJwt, this.customClaims = const {}});
}
