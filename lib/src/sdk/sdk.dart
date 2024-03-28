// ignore_for_file: deprecated
import '/src/internal/http/descope_client.dart';
import '/src/internal/routes/auth.dart';
import '/src/internal/routes/enchanted_link.dart';
import '/src/internal/routes/flow.dart';
import '/src/internal/routes/magic_link.dart';
import '/src/internal/routes/oauth.dart';
import '/src/internal/routes/otp.dart';
import '/src/internal/routes/passkey.dart';
import '/src/internal/routes/password.dart';
import '/src/internal/routes/sso.dart';
import '/src/internal/routes/totp.dart';
import '/src/session/lifecycle.dart';
import '/src/session/manager.dart';
import '/src/session/storage.dart';
import 'config.dart';
import 'routes.dart';

/// Provides functions for working with the Descope API.
class DescopeSdk {
  /// The Descope SDK name
  static const name = 'DescopeFlutter';

  /// The Descope SDK version
  static const version = '0.9.0';

  /// The configuration of the [DescopeSdk] instance.
  final DescopeConfig config;

  /// Authenticate using an authentication flow
  final DescopeFlow flow;

  /// General functions
  final DescopeAuth auth;

  /// Authentication with one time codes
  final DescopeOtp otp;

  /// Authentication with TOTP
  final DescopeTotp totp;

  /// Authentication with magic links
  final DescopeMagicLink magicLink;

  /// Authentication with enchanted links
  final DescopeEnchantedLink enchantedLink;

  /// Authentication with OAuth
  final DescopeOAuth oauth;

  /// Authentication with SSO
  final DescopeSso sso;

  /// Authentication with passkeys
  final DescopePasskey passkey;

  /// Authentication with passwords
  final DescopePassword password;

  DescopeSessionManager sessionManager;

  /// Creates a new [DescopeSdk].
  ///
  /// The [projectId] of the Descope project can be found in the project page in
  /// the Descope console. Use the optional [configure] function to
  /// finely configure the Descope SDK.
  factory DescopeSdk(String projectId, [Function(DescopeConfig)? configure]) {
    // init config
    final config = DescopeConfig(projectId: projectId);
    configure?.call(config);
    // init auth methods
    final client = DescopeClient(config);
    return DescopeSdk._internal(config, Flow(client), Auth(client), Otp(client), Totp(client), MagicLink(client), EnchantedLink(client), OAuth(client), Sso(client), Passkey(client), Password(client));
  }

  DescopeSdk._internal(this.config, this.flow, this.auth, this.otp, this.totp, this.magicLink, this.enchantedLink, this.oauth, this.sso, this.passkey, this.password) :
    sessionManager = DescopeSessionManager(SessionStorage(projectId: config.projectId), SessionLifecycle(auth));
}
