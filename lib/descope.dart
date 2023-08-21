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
class Descope {
  /// The projectId of your Descope project.
  ///
  /// You will most likely want to set this value in your application's initialization code,
  /// and in most cases you only need to set this to work with the `Descope` singleton.
  ///
  /// **Note:** This is a shortcut for setting the [Descope.config] property.
  static String get projectId => _config.projectId;

  static set projectId(String projectId) {
    _config = DescopeConfig(projectId: projectId);
  }

  /// The configuration of the `Descope` singleton.
  ///
  /// Set this property **instead** of [Descope.projectId] in your application's initialization code
  /// if you require additional configuration.
  ///
  /// **Important:** To prevent accidental misuse only one of `config` and `projectId` can
  /// be set, and they can only be set once. If this isn't appropriate for your use
  /// case you can also use the [DescopeSdk] class directly instead.
  static DescopeConfig get config => _config;

  static set config(DescopeConfig config) {
    assert(_config.projectId == '');
    _config = config;
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

  /// Authentication with passwords.
  static DescopePassword get password => _sdk.password;

  // The backing field for the config property.
  static DescopeConfig _config = DescopeConfig.initial;

  // The underlying DescopeSdk object used by the Descope singleton.
  static final DescopeSdk _sdk = DescopeSdk(config);

  // This class cannot be instantiated.
  Descope._();
}
