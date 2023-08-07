library descope_flutter;

import '/src/sdk/config.dart';
import '/src/sdk/routes.dart';
import '/src/sdk/sdk.dart';
import '/src/session/manager.dart';
import '/src/session/session.dart';

export '/src/sdk/config.dart' show DescopeConfig;
export '/src/sdk/routes.dart';
export '/src/sdk/sdk.dart' show DescopeSdk;
export '/src/session/session.dart' show DescopeSession;
export '/src/session/token.dart' show DescopeToken;
export '/src/types/others.dart';
export '/src/types/responses.dart';

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
  /// - **Note:** This is a shortcut for setting the [Descope.config] property.
  static String _projectId = "";

  static String get projectId => _projectId;

  static set projectId(String projectId) {
    _config = DescopeConfig(projectId);
    _projectId = projectId;
  }

  /// The configuration of the `Descope` singleton.
  ///
  /// Set this property **instead** of [Descope.projectId] in your application's initialization code
  /// if you require additional configuration.
  ///
  /// - **Important:** To prevent accidental misuse only one of `config` and `projectId` can
  ///     be set, and they can only be set once. If this isn't appropriate for your use
  ///     case you can also use the [DescopeSdk] class directly instead.
  static DescopeConfig _config = DescopeConfig.initial;

  static DescopeConfig get config => _config;

  static set config(DescopeConfig config) {
    assert(config.projectId != "");
    _config = config;
  }

  /// Manages the storage and lifetime of a [DescopeSession].
  ///
  /// You can use this [DescopeSessionManager] object as a shared instance to manage
  ///  authenticated sessions in your application.
  ///
  ///    final authResponse = Descope.otp.verify(DeliveryMethod.Email, "andy@example.com", "123456")
  ///    val session = DescopeSession(authResponse)
  ///    Descope.sessionManager.manageSession(session)
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

  // The underlying `DescopeSdk` object used by the `Descope` singleton.
  static late final DescopeSdk _sdk = DescopeSdk(config);

  // cannot be instantiated
  Descope._();
}

extension DescopeInfo on Descope {
  /// The Descope SDK name
  static String get name => 'DescopeFlutter';

  /// The Descope SDK version
  static String get version => '0.5.1';
}
