import '/src/session/session.dart';
import '/src/types/flows.dart';
import '/src/types/others.dart';
import '/src/types/responses.dart';
import '/src/types/user.dart';

/// General authentication functions
abstract class DescopeAuth {
  /// Returns details about the user.
  ///
  /// The user must have an active [DescopeSession] whose [refreshJwt] should be
  /// passed as a parameter to this function.
  Future<DescopeUser> me(String refreshJwt);

  /// Refreshes a [DescopeSession].
  ///
  /// This can be called at any time as long as the [refreshJwt] is still
  /// valid. Typically called when a [DescopeSession]'s [sessionJwt] is expired
  /// or is about expire.
  Future<RefreshResponse> refreshSession(String refreshJwt);

  /// It's a good security practice to remove refresh JWTs from the Descope servers if
  /// they become redundant before expiry. This function will called with a [RevokeType], usually [RevokeType.currentSession],
  /// and a valid refresh JWT when the user wants to sign out of the application. For example:
  ///
  ///     void logout() {
  ///         // clear the session locally from the app and spawn a background task to revoke
  ///         // the refreshJWT from the Descope servers without waiting for the call to finish
  ///         final refreshJwt = Descope.sessionManager.session?.refreshToken.jwt;
  ///         if (refreshJwt != null) {
  ///           Descope.sessionManager.clearSession();
  ///           try {
  ///             Descope.auth.revokeSessions(RevokeType.currentSession, refreshJwt);
  ///           } catch (e) {
  ///             // handle errors
  ///           }
  ///           showLaunchScreen();
  ///         }
  ///     }
  ///
  /// - Important: When called with [RevokeType.allSessions] the provided refresh JWT will not
  ///     be usable anymore and the user will need to sign in again.
  Future<void> revokeSessions(RevokeType revokeType, String refreshJwt);

  // Deprecated

  /// Logs out from an active [DescopeSession].
  @Deprecated('Use revokeSessions instead')
  Future<void> logout(String refreshJwt);
}

/// Authenticate a user using a flow.
///
/// Descope Flows is a visual no-code interface to build screens and authentication flows
/// for common user interactions with your application. On mobile platforms,
/// Flows are hosted on a webpage and are run using a sandboxed browser view.
/// On the web, they are embedded into the running web-app.
///
/// Under the hood, this authentication method uses platform specific classes to
/// display the flows: `ASWebAuthenticationSession` on iOS, `Chrome Custom Tabs` on Android,
/// and `Web Components` on the web.
/// If targeting Android you need to set up `Android App Links` in order to communicate back
/// to the application. Read more about it in the README under the `Running Flows` section.
abstract class DescopeFlow {

  /// Starts a user authentication flow.
  ///
  /// The flow presentation differs according to the target:
  /// - On mobile platforms - screens are presented in a sandboxed browser view that's displayed by this
  /// method call.
  /// - On the web - the screens are embedded into the active browser window.
  ///
  /// The method then waits until the authentication completed successfully,
  /// at which point it will return an [AuthenticationResponse] as in all other
  /// authentication methods. Provide this call with a [DescopeFlowOptions] that
  /// contains all of the required information to run the flow on different targets.where the flow
  ///
  /// When targeting Android: The [DescopeFlowOptions.mobile.deepLinkUrl] is required
  /// in order to return a result from the flow. This result URI should then be
  /// processed by the [exchange] function.
  Future<AuthenticationResponse> start(DescopeFlowOptions options);

  /// Resumes an ongoing **mobile** flow after a redirect back to the app with an [incomingUri].
  /// This is required for *Magic Link only* at this stage.
  ///
  /// **Note:** This requires additional setup on the application side.
  /// See the README for more details.
  ///
  /// **Note:** Do not call this method when running web flows. Use [start] instead.
  Future<void> resume(Uri incomingUri);

  /// Exchange a URI for an [AuthenticationResponse].
  ///
  /// This method should be called only when targeting Android.
  /// When a flow completes successfully, the result will be sent through
  /// the configured deep link URL. However, it must still be exchanged for an
  /// actual [AuthenticationResponse] to complete the authentication flow.
  /// The [AuthenticationResponse] will be returned to the original call to [start].
  void exchange(Uri incomingUri);

  /// Cancel the current flow.
  ///
  /// This function is only supported when targeting the web, and should
  /// be used in order to cancel out of a running flow.
  /// As all websites are different, feel free to define your own UX
  /// and call this function to cancel and remove any running flow.
  void cancel();
}

/// Authenticate users using a one time password (OTP) code, sent via
/// a delivery method of choice. The code then needs to be verified using
/// the [verify] function. It is also possible to add an email or phone to
/// an existing user after validating it via OTP.
abstract class DescopeOtp {
  /// Authenticates a new user using an OTP
  ///
  /// The OTP code will be sent to the user identified by [loginId]
  /// via a delivery [method] of choice.
  ///
  /// **Important:** Make sure the delivery information corresponding with
  /// the delivery [method] is given either in the optional [details] parameter or as
  /// the [loginId] itself, i.e., the email address, phone number, etc.
  Future<String> signUp({required DeliveryMethod method, required String loginId, SignUpDetails? details});

  /// Authenticates an existing user using an OTP
  ///
  /// The OTP code will be sent to the user identified by [loginId]
  /// via a delivery [method] of choice.
  Future<String> signIn({required DeliveryMethod method, required String loginId, SignInOptions? options});

  /// Authenticates an existing user if one exists, or creates a new user
  /// using an OTP
  ///
  /// The OTP code will be sent to the user identified by [loginId]
  /// via a delivery [method] of choice.
  ///
  /// **Important**: Make sure the delivery information corresponding with
  /// the delivery [method] is given either in the optional [user] parameter or as
  /// the [loginId] itself, i.e., the email address, phone number, etc.
  Future<String> signUpOrIn({required DeliveryMethod method, required String loginId, SignInOptions? options});

  /// Verifies an OTP [code] sent to the user.
  ///
  /// Provide this functions with the [loginId] and [method] of delivery used to
  /// send the [code]. Upon successful authentication an [AuthenticationResponse] is returned.
  Future<AuthenticationResponse> verify({required DeliveryMethod method, required String loginId, required String code});

  /// Updates an existing user by adding an email address.
  ///
  /// The [email] will be updated for the user identified by [loginId]
  /// after it is verified via OTP. In order to do this, the user must
  /// have an active [DescopeSession] whose [refreshJwt] should be
  /// passed as a parameter to this function.
  ///
  /// You can optionally pass the [options] parameter to add the new email address
  /// as a `loginId` for the updated user, and to determine how to resolve conflicts
  /// if another user already exists with the same `loginId`. See the documentation
  /// for `UpdateOptions` for more details.
  Future<String> updateEmail({required String email, required String loginId, required String refreshJwt, UpdateOptions? options});

  /// Updates an existing user by adding a phone number.
  ///
  /// The [phone] number will be updated for the user identified by [loginId]
  /// after it is verified via OTP. In order to do this, the user must
  /// have an active [DescopeSession] whose [refreshJwt] should be
  /// passed as a parameter to this function.
  ///
  /// You can optionally pass the [options] parameter to add the new phone number
  /// as a `loginId` for the updated user, and to determine how to resolve conflicts
  /// if another user already exists with the same `loginId`. See the documentation
  /// for `UpdateOptions` for more details.
  ///
  /// **Important:** Make sure delivery [method] is appropriate for using a phone number.
  Future<String> updatePhone({required String phone, required DeliveryMethod method, required String loginId, required String refreshJwt, UpdateOptions? options});
}

/// Authenticate users using Timed One-time Passwords (TOTP) codes.
///
/// This authentication method is geared towards using an authenticator app which
/// can produce TOTP codes.
abstract class DescopeTotp {
  /// Authenticates a new user using a TOTP.
  ///
  /// This function creates a new user identified by [loginId] and
  /// the optional information provided on via the [details] object.
  /// It returns a [TotpResponse.key] (seed) that allows
  /// authenticator apps to generate TOTP codes. The same information
  /// is returned in multiple formats.
  Future<TotpResponse> signUp({required String loginId, SignUpDetails? details});

  /// Updates an existing user by adding TOTP as an authentication method.
  ///
  /// In order to do this, the user identified by [loginId] must have an active
  /// [DescopeSession] whose [refreshJwt] should be passed as a parameter to this function.
  ///
  /// This function returns a [TotpResponse.key] (seed) that allows
  /// authenticator apps to generate TOTP codes. The same information
  /// is returned in multiple formats.
  Future<TotpResponse> update({required String loginId, required String refreshJwt});

  /// Verifies a TOTP code that was generated by an authenticator app.
  ///
  /// Returns an [AuthenticationResponse] if the provided [loginId] and the [code]
  /// generated by an authenticator app match.
  Future<AuthenticationResponse> verify({required String loginId, required String code, SignInOptions? options});
}

/// Authenticate users using a password.
abstract class DescopePassword {
  /// Creates a new user that can later sign in with a password.
  ///
  /// Uses [loginId] to identify the user, typically an email, phone,
  /// or any other unique identifier. The provided [password] will allow
  /// the user to sign in in the future and must conform to the password policy
  /// defined in the password settings in the Descope console.
  /// The optional [details] provides additional details about the user signing up.
  /// Returns an [AuthenticationResponse] upon successful authentication.
  Future<AuthenticationResponse> signUp({required String loginId, required String password, SignUpDetails? details});

  /// Authenticates an existing user using a password.
  ///
  /// Matches the provided [loginId] and [password].
  /// Returns an [AuthenticationResponse] upon successful authentication.
  Future<AuthenticationResponse> signIn({required String loginId, required String password});

  /// Updates a user's password.
  ///
  /// In order to do this, the user must have an active [DescopeSession] whose
  /// [refreshJwt] should be passed as a parameter to this function.
  ///
  /// Updates the user identified by [loginId] with [newPassword].
  /// [newPassword] must conform to the password policy defined in the
  /// password settings in the Descope console
  Future<void> update({required String loginId, required String newPassword, required String refreshJwt});

  /// Replaces a user's password by providing their current password.
  ///
  /// Updates the user identified by [loginId] and [oldPassword] with [newPassword].
  /// [newPassword] must conform to the password policy defined in the
  /// password settings in the Descope console
  /// Returns an [AuthenticationResponse] upon successful replacement and authentication.
  Future<AuthenticationResponse> replace({required String loginId, required String oldPassword, required String newPassword});

  /// Sends a password reset email to the user.
  ///
  /// This operation starts a Magic Link flow for the user identified by
  /// [loginId] depending on the configuration in the Descope console. An optional
  /// [redirectUrl] can be provided to the magic link method.
  /// After the authentication flow is finished
  /// use the [refreshJwt] to call [update] and change the user's password.
  ///
  /// **Important:** The user must be verified according to the configured
  /// password reset method.
  Future<void> sendReset({required String loginId, String? redirectUrl});

  /// Fetches the rules for valid passwords.
  ///
  /// The [PasswordPolicy] is configured in the password settings in the Descope console, and
  /// these values can be used to implement client-side validation of new user passwords
  /// for a better user experience.
  ///
  /// In any case, all password rules are enforced by Descope on the server side as well.
  Future<PasswordPolicy> getPolicy();
}

/// Authenticate users using a special link that once clicked, can authenticate
/// the user.
///
/// In order to correctly implement, the app must make sure the link redirects back
/// to the app. Read more on [universal links](https://developer.apple.com/ios/universal-links/)
/// and [app links](https://developer.android.com/training/app-links)
/// to learn more. Once redirected back to the app, call the [verify] function
/// on the appended token URL parameter.
abstract class DescopeMagicLink {
  /// Authenticates a new user using a magic link.
  ///
  /// The magic link will be sent to the user identified by [loginId]
  /// via a delivery [method] of choice.
  ///
  /// **Important:** Make sure the delivery information corresponding with
  /// the delivery [method] is given either in the optional [details] parameter or as
  /// the [loginId] itself, i.e., the email address, phone number, etc.
  ///
  /// **Important:** Make sure a default magic link URL is configured
  /// in the Descope console, or provided by this call via [redirectUrl].
  Future<String> signUp({required DeliveryMethod method, required String loginId, SignUpDetails? details, String? redirectUrl});

  /// Authenticates an existing user using a magic link.
  ///
  /// The magic link will be sent to the user identified by [loginId]
  /// via a delivery [method] of choice.
  ///
  /// **Important:** Make sure a default magic link URL is configured
  /// in the Descope console, or provided by this call via [redirectUrl].
  Future<String> signIn({required DeliveryMethod method, required String loginId, String? redirectUrl, SignInOptions? options});

  /// Authenticates an existing user if one exists, or creates a new user
  /// using a magic link.
  ///
  /// The magic link will be sent to the user identified by [loginId]
  /// via a delivery [method] of choice.
  ///
  /// **Important:** Make sure the delivery information corresponding with
  /// the delivery [method] is given either in the optional [user] parameter or as
  /// the [loginId] itself, i.e., the email address, phone number, etc.
  ///
  /// **Important:** Make sure a default magic link URL is configured
  /// in the Descope console, or provided by this call via [redirectUrl].
  Future<String> signUpOrIn({required DeliveryMethod method, required String loginId, String? redirectUrl, SignInOptions? options});

  /// Updates an existing user by adding an [email] address.
  ///
  /// The [email] will be updated for the user identified by [loginId]
  /// after it is verified via magic link. In order to do this,
  /// the user must have an active [DescopeSession] whose [refreshJwt] should
  /// be passed as a parameter to this function.
  ///
  /// You can optionally pass the [options] parameter to add the new email address
  /// as a `loginId` for the existing user, and to determine how to resolve conflicts
  /// if another user already exists with the same `loginId`. See the documentation
  /// for `UpdateOptions` for more details.
  ///
  /// **Important:** Make sure a default magic link URL is configured
  /// in the Descope console, or provided by this call via [redirectUrl].
  Future<String> updateEmail({required String email, required String loginId, String? redirectUrl, required String refreshJwt, UpdateOptions? options});

  /// Updates an existing user by adding a [phone] number.
  ///
  /// The [phone] number will be updated for the user identified by [loginId]
  /// after it is verified via magic link. In order to do this,
  /// the user must have an active [DescopeSession] whose [refreshJwt] should
  /// be passed as a parameter to this function.
  ///
  /// You can optionally pass the [options] parameter to add the new phone number
  /// as a `loginId` for the existing user, and to determine how to resolve conflicts
  /// if another user already exists with the same `loginId`. See the documentation
  /// for `UpdateOptions` for more details.
  ///
  /// **Important:** Make sure the delivery information corresponding with
  /// the phone number enabled delivery [method].
  ///
  /// **Important:** Make sure a default magic link URL is configured
  /// in the Descope console, or provided by this call via [redirectUrl].
  Future<String> updatePhone({required String phone, required DeliveryMethod method, required String loginId, String? redirectUrl, required String refreshJwt, UpdateOptions? options});

  /// Verifies a magic link [token].
  ///
  /// In order to effectively do this, the link generated should refer back to
  /// the app, then the `t` URL parameter should be extracted and sent to this
  /// function. Upon successful authentication an [AuthenticationResponse] is returned.
  Future<AuthenticationResponse> verify({required String token});
}

/// Authenticate users using one of three special links that once clicked,
/// can authenticate the user.
///
/// This method is geared towards cross-device authentication. In order to
/// correctly implement, the app must make sure the URL redirects to a webpage
/// which will verify the link for them. The app will poll for a valid session
/// in the meantime, and will authenticate the user as soon as they are
/// verified via said webpage. To learn more consult the
/// official Descope docs.
abstract class DescopeEnchantedLink {
  /// Authenticates a new user using an enchanted link, sent via email.
  ///
  /// A new user identified by [loginId] and the optional [details] details will be added
  /// upon successful authentication.
  /// The caller should use the returned [EnchantedLinkResponse.linkId] to show the
  /// user which link they need to press in the enchanted link email, and then use
  /// the [EnchantedLinkResponse.pendingRef] value to poll until the authentication is verified.
  ///
  /// **Important:** Make sure an email address is provided via
  /// the [details] parameter or as the [loginId] itself.
  ///
  /// **Important:** Make sure a default enchanted link URL is configured
  /// in the Descope console, or provided via [redirectUrl] by this call.
  Future<EnchantedLinkResponse> signUp({required String loginId, SignUpDetails? details, String? redirectUrl});

  /// Authenticates an existing user using an enchanted link, sent via email.
  ///
  /// An enchanted link will be sent to the user identified by [loginId].
  /// The caller should use the returned [EnchantedLinkResponse.linkId] to show the
  /// user which link they need to press in the enchanted link email, and then use
  /// the [EnchantedLinkResponse.pendingRef] value to poll until the authentication is verified.
  ///
  /// **Important:** Make sure a default enchanted link URL is configured
  /// in the Descope console, or provided via [redirectUrl] by this call.
  Future<EnchantedLinkResponse> signIn({required String loginId, String? redirectUrl, SignInOptions? options});

  /// Authenticates an existing user if one exists, or create a new user using an
  /// enchanted link, sent via email.
  ///
  /// The caller should use the returned [EnchantedLinkResponse.linkId] to show the
  /// user which link they need to press in the enchanted link email, and then use
  /// the [EnchantedLinkResponse.pendingRef] value to poll until the authentication is verified.
  ///
  /// **Important:** Make sure a default enchanted link URL is configured
  /// in the Descope console, or provided via [redirectUrl] by this call.
  Future<EnchantedLinkResponse> signUpOrIn({required String loginId, String? redirectUrl, SignInOptions? options});

  /// Updates an existing user by adding an email address.
  ///
  /// The [email] will be updated after it is verified via enchanted link. In order to
  /// do this, the user must have an active [DescopeSession] whose [refreshJwt] should
  /// be passed as a parameter to this function.
  ///
  /// The caller should use the returned [EnchantedLinkResponse.linkId] to show the
  /// user which link they need to press in the enchanted link email, and then use
  /// the [EnchantedLinkResponse.pendingRef] value to poll until the authentication is verified.
  ///
  /// You can optionally pass the [options] parameter to add the new email address
  /// as a `loginId` for the existing user, and to determine how to resolve conflicts
  /// if another user already exists with the same `loginId`. See the documentation
  /// for `UpdateOptions` for more details.
  Future<EnchantedLinkResponse> updateEmail({required String email, required String loginId, String? redirectUrl, required String refreshJwt, UpdateOptions? options});

  /// Checks if an enchanted link authentication has been verified by the user.
  ///
  /// Provide this function with a [pendingRef] received by [signUp], [signIn], [signUpOrIn] or [updateEmail].
  /// This function will only return an [AuthenticationResponse] successfully after the user
  /// presses the enchanted link in the authentication email.
  ///
  /// **Important:** This function doesn't perform any polling or waiting, so calling code
  /// should expect to catch any thrown exceptions and
  /// handle them appropriately. For most use cases it might be more convenient to
  /// use [pollForSession] instead.
  Future<AuthenticationResponse> checkForSession({required String pendingRef});

  /// Waits until an enchanted link authentication has been verified by the user.
  ///
  /// Provide this function with a [pendingRef] received by [signUp], [signIn], [signUpOrIn] or [updateEmail].
  /// This function will only return an [AuthenticationResponse] successfully after the user
  /// presses the enchanted link in the authentication email.
  ///
  /// This function calls [checkForSession] periodically until the authentication
  /// is verified. It will keep polling even if it encounters network errors, but
  /// any other unexpected errors will be rethrown. If the [timeout] expires a
  /// `DescopeError.enchantedLinkExpired` error is thrown.
  /// [timeout] is an optional duration to poll for until giving up. If not
  /// given a default value of 2 minutes is used.
  ///
  /// To cancel it, you can wrap the response in a [CancelableOperation](https://pub.dev/documentation/async/latest/async/CancelableOperation-class.html).
  Future<AuthenticationResponse> pollForSession({required String pendingRef, Duration? timeout});
}

/// Authenticate a user using an OAuth provider.
///
/// Use the Descope console to configure which authentication provider you'd like to support.
///
/// It's recommended to use `flutter_web_auth` to perform the authentication.
/// For further reference see: [flutter_web_auth](https://pub.dev/packages/flutter_web_auth)
abstract class DescopeOAuth {
  /// Starts an OAuth redirect chain to authenticate a user.
  ///
  ///     // use one of the built in constants for the OAuth provider
  ///     final authUrl = await Descope.oauth.start(provider: OAuthProvider.google);
  ///
  ///     // or pass a string with the name of a custom provider
  ///     final authUrl = await Descope.oauth.start(provider: OAuthProvider.named("myprovider"));
  ///
  /// This function returns a URL to redirect to in order to
  /// authenticate the user against the chosen [provider].
  ///
  /// It's recommended to use `flutter_web_auth` to perform the authentication.
  ///
  /// **Important:** Make sure a default OAuth redirect URL is configured
  /// in the Descope console, or provided by this call via [redirectUrl].
  Future<String> start({required OAuthProvider provider, String? redirectUrl, SignInOptions? options});

  /// Completes an OAuth redirect chain.
  ///
  /// This function exchanges the [code] received in the `code` URL
  /// parameter for an [AuthenticationResponse].
  Future<AuthenticationResponse> exchange({required String code});

  /// Authenticates the user using the native Sign in with Apple/Google dialogs on these
  /// platforms.
  ///
  /// This API enables a more streamlined user experience than the equivalent browser
  /// based OAuth authentication, when using the appropriate provider on iOS/Android
  /// devices. The authentication presents a native dialog that lets the user sign in
  /// with the account they're already using on their device.
  ///
  /// This function expects the name of the provider the user wishes to authenticate with,
  /// this will usually be either, `Apple`, `Google` or the name of a custom provider that's
  /// configured for OAuth with one of them.
  ///
  /// Note: This is an asynchronous operation that performs network requests before and
  /// after displaying the modal authentication view. It is thus recommended to switch the
  /// user interface to a loading state before calling this function, otherwise the user
  /// might accidentally interact with the app when the authentication view is not
  /// being displayed.
  ///
  /// If you haven't already configured your app to support Sign in with Google you'll
  /// probably need to set up your [Google APIs console project](https://developers.google.com/identity/one-tap/android/get-started#api-console)
  /// for this. You should also configure an OAuth provider for Google in the in the
  /// [Descope console](https://app.descope.com/settings/authentication/social),
  /// with its `Grant Type` set to `Implicit`. Also note that the `Client ID` and
  /// `Client Secret` should be set to the values of your `Web application` OAuth client,
  /// rather than those from the `Android` OAuth client. For more details see the
  /// [Credential Manager documentation](https://developer.android.com/training/sign-in/credential-manager).
  ///
  /// The Sign in with Apple APIs require some setup in your Xcode project, including
  /// at the very least adding the `Sign in with Apple` capability. You will also need
  /// to configure the Apple provider in the [Descope console](https://app.descope.com/settings/authentication/social).
  /// In particular, when using your own account make sure that the `Client ID` value
  /// matches the Bundle Identifier of your app. For more details see the
  /// [Sign in with Apple documentation](https://developer.apple.com/sign-in-with-apple/get-started/).
  Future<AuthenticationResponse> native({required OAuthProvider provider, SignInOptions? options});
}

/// Authenticate a user using SSO.
///
/// Use the Descope console to configure your SSO details in order for this method to work properly.
///
/// It's recommended to use `flutter_web_auth` to perform the authentication.
/// For further reference see: [flutter_web_auth](https://pub.dev/packages/flutter_web_auth)
abstract class DescopeSso {
  /// Starts an SSO redirect chain to authenticate a user.
  ///
  /// This function returns a URL to redirect to in order to
  /// authenticate the user according to the provided [emailOrTenantId].
  ///
  /// It's recommended to use `flutter_web_auth` to perform the authentication.
  ///
  /// **Important:** Make sure a SSO is set up correctly and a redirect URL is configured
  /// in the Descope console, or provided by this call via [redirectUrl].
  Future<String> start({required String emailOrTenantId, String? redirectUrl, SignInOptions? options});

  /// Completes an SSO redirect chain.
  ///
  /// This function exchanges the [code] received in the `code` URL
  /// parameter for an [AuthenticationResponse].
  Future<AuthenticationResponse> exchange({required String code});
}

/// Authenticate users using passkeys.
///
/// The authentication operations in this class are all async functions that
/// perform network requests before and after displaying the modal authentication view.
/// It is thus recommended to switch the user interface to a loading state before calling
/// these functions, otherwise the user might accidentally interact with the app when the
/// authentication view is not being displayed.
///
/// #### Important: Some set up is required before authentication with passkeys is possible.
/// - For Android, please follow the [Add support for Digital Asset Links](https://developer.android.com/training/sign-in/passkeys#add-support-dal)
/// setup, as described in the official Google docs.
/// - For iOS, go through Apple's [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_passkeys/)
/// guide, in particular be sure to have an associated domain configured for your app
/// with the `webcredentials` service type, whose value matches the top level domain
/// you configured in the Descope console earlier.
abstract class DescopePasskey {
  /// Checks whether Passkeys are supported on this device
  Future<bool> isSupported();

  /// Authenticates a new user by creating a new passkey.
  ///
  /// This function creates a new user identified by [loginId] and
  /// the optional information provided via the [details] object.
  /// If will only return an [AuthenticationResponse] successfully after the user
  /// creates a new passkey using their device.
  Future<AuthenticationResponse> signUp({required String loginId, SignUpDetails? details});

  /// Authenticates an existing user by prompting for an existing passkey.
  ///
  /// This function will only return an [AuthenticationResponse] successfully after the user
  /// identified by [loginId] uses their existing passkey on their device.
  Future<AuthenticationResponse> signIn({required String loginId, SignInOptions? options});

  /// Authenticates an existing user if one exists or creates a new one.
  ///
  /// A new passkey will be created if the user identified by [loginId] doesn't already exist,
  /// otherwise a passkey must be available on their device to authenticate with.
  ///
  /// This function will only return an [AuthenticationResponse] successfully after the user
  /// identified by [loginId] uses their existing passkey on their device or creates a new
  /// one, if the user is being created.
  Future<AuthenticationResponse> signUpOrIn({required String loginId, SignInOptions? options});

  /// Updates an existing user by adding a new passkey as an authentication method.
  ///
  /// The user identified by [loginId] must have an active [DescopeSession] whose [refreshJwt] should
  /// be passed as a parameter to this function.
  Future<void> add({required String loginId, required String refreshJwt});
}
