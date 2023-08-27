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
  ///     const options = SignInOptions(customClaims: {'name': '{{user.name}}'});
  ///     await Descope.otp.signIn(method: DeliveryMethod.email, loginId: email, options: options);
  ///
  /// **Important:** Any custom claims added via this method are considered insecure and will
  /// be nested under the `nsec` custom claim.
  final Map<String, dynamic> customClaims;

  const SignInOptions({this.stepupRefreshJwt, this.mfaRefreshJwt, this.customClaims = const {}});
}

/// Used to configure how users are updated.
class UpdateOptions {
  /// Whether to allow sign in from a new `loginId` after an update.
  ///
  /// When a user's email address or phone number are updated and this is set to `true`
  /// the new value is added to the user's list of `loginIds`, and the user from that
  /// point on will be able to use it to sign in.
  final bool addToLoginIds;

  /// Whether to keep or delete the current user when merging two users after an update.
  ///
  /// When updating a user's email address or phone number and with `addToUserLoginIds`
  /// set to `true`, if another user in the the system already has the same email address
  /// or phone number as the one being added in their list of `loginIds` the two users
  /// are merged and one of them is deleted.
  ///
  /// This scenario can happen when a user uses multiple authentication methods
  /// and ends up with multiple accounts. For example, a user might sign in with
  /// their email address at first. Then at some point later they reinstall the
  /// app and use OAuth to authenticate, and a new user account is created. If
  /// the user then updates their account and adds their email address the
  /// two accounts need to be merged.
  ///
  /// Let's define the "updated user" to be the user being updated and whom
  /// the `refreshJwt` belongs to, and the "existing user" to be another user in
  /// the system with the same `loginId`.
  ///
  /// By default, the updated user is kept, the existing user's details are merged
  /// into the updated user, and the existing user is then deleted.
  ///
  /// If this option is set to `true` however then the updated user is merged into
  /// the existing user, and the updated user is deleted. In this case the [DescopeSession]
  /// and its `refreshJwt` that was used to initiate the update operation will no longer
  /// be valid, and an [AuthenticationResponse] is returned for the existing user instead.
  final bool onMergeUseExisting;

  const UpdateOptions({this.addToLoginIds = false, this.onMergeUseExisting = false});
}
