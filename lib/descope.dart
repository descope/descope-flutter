/// A package that provides convenient access to the Descope user management and
/// authentication APIs for Flutter apps.
library descope_flutter;

import '/src/sdk/config.dart';
import '/src/sdk/routes.dart';
import '/src/sdk/sdk.dart';
import '/src/session/manager.dart';
import '/src/session/session.dart';

export '/src/extensions/request.dart';
export '/src/sdk/config.dart' show DescopeConfig, DescopeLogger, DescopeNetworkClient;
export '/src/sdk/routes.dart';
export '/src/sdk/sdk.dart' show DescopeSdk;
export '/src/session/lifecycle.dart' show DescopeSessionLifecycle, SessionLifecycle;
export '/src/session/session.dart' show DescopeSession;
export '/src/session/storage.dart' show DescopeSessionStorage, SessionStorage, SessionStorageStore;
export '/src/session/token.dart' show DescopeToken;
export '/src/types/others.dart';
export '/src/types/responses.dart';
export '/src/types/user.dart' show DescopeUser;
export '/src/types/error.dart';

/// Provides functions for working with the Descope API.
///
/// This singleton object is provided as a convenience that should be suitable for most
/// app architectures. If you prefer a different approach you can also create an instance
/// of the [DescopeSdk] class instead.
///
/// - **Important**: Make sure to call the [setup] function when initializing your application.
class Descope {
  /// The setup of the `Descope` singleton.
  ///
  /// Call this function when initializing you application.
  ///
  /// **This function must be called before the [Descope] object can be used**
  ///
  /// The [projectId] of the Descope project can be found in the project page in
  /// the Descope console. Use the optional [configure] function to
  /// finely configure the Descope SDK.
  static void setup(String projectId, [Function(DescopeConfig)? configure]) {
    _sdk = DescopeSdk(projectId, configure);
  }

  /// Manages the storage and lifetime of a [DescopeSession].
  ///
  /// You can use this [DescopeSessionManager] object as a shared instance to manage
  /// authenticated sessions in your application.
  ///
  ///     final authResponse = Descope.otp.verify(DeliveryMethod.email, 'andy@example.com', '123456')
  ///     final session = DescopeSession(authResponse)
  ///     Descope.sessionManager.manageSession(session)
  ///
  /// See the documentation for [DescopeSessionManager] for more details.
  static DescopeSessionManager get sessionManager => _sdk.sessionManager;

  static set sessionManager(DescopeSessionManager sessionManager) {
    _sdk.sessionManager = sessionManager;
  }

  /// Authenticate using an authentication flow
  static DescopeFlow get flow => _sdk.flow;

  /// General functions.
  static DescopeAuth get auth => _sdk.auth;

  /// Authentication with OTP codes via email or phone.
  static DescopeOtp get otp => _sdk.otp;

  /// Authentication with TOTP codes.
  static DescopeTotp get totp => _sdk.totp;

  /// Authentication with magic links.
  static DescopeMagicLink get magicLink => _sdk.magicLink;

  /// Authentication with enchanted links.
  static DescopeEnchantedLink get enchantedLink => _sdk.enchantedLink;

  /// Authentication with OAuth.
  static DescopeOAuth get oauth => _sdk.oauth;

  /// Authentication with SSO.
  static DescopeSso get sso => _sdk.sso;

  /// Authentication with passkeys.
  static DescopePasskey get passkey => _sdk.passkey;

  /// Authentication with passwords.
  static DescopePassword get password => _sdk.password;

  // The underlying DescopeSdk object used by the Descope singleton.
  static late final DescopeSdk _sdk;

  // This class cannot be instantiated.
  Descope._();
}
