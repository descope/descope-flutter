import 'config.dart';
import 'http/descope_client.dart';
import 'routes.dart';
import 'routes/auth.dart';
import 'routes/enchanted_link.dart';
import 'routes/magic_link.dart';
import 'routes/oauth.dart';
import 'routes/otp.dart';
import 'routes/password.dart';
import 'routes/sso.dart';
import 'routes/totp.dart';
import 'session/lifecycle.dart';
import 'session/manager.dart';
import 'session/storage.dart';

/// Provides functions for working with the Descope API.
class DescopeSdk {
  /// The configuration of the [DescopeSdk] instance.
  final DescopeConfig config;

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

  /// Authentication with passwords
  final DescopePassword password;

  // defer initialization to allow setting a custom manager without loading the current state
  DescopeSessionManager? _sessionManager;

  DescopeSessionManager get sessionManager => _sessionManager ?? _initDefaultManager();

  set sessionManager(DescopeSessionManager manager) => _sessionManager = manager;

  DescopeSessionManager _initDefaultManager() {
    final manager = DescopeSessionManager(SessionStorage(config.projectId), SessionLifecycle(auth));
    _sessionManager = manager;
    return manager;
  }

  /// Creates a new [DescopeSdk] instance with the given [DescopeConfig].
  ///
  /// The [projectId] of the Descope project can be found in the project page in
  /// the Descope console. The [baseUrl] is an  optional override for the URL of
  /// the Descope server, in case you need to access it through a CNAME record.
  factory DescopeSdk(DescopeConfig config) {
    var client = DescopeClient(config);
    return DescopeSdk._internal(config, Auth(client), Otp(client), Totp(client), Password(client), MagicLink(client), EnchantedLink(client), OAuth(client), Sso(client));
  }

  DescopeSdk._internal(this.config, this.auth, this.otp, this.totp, this.password, this.magicLink, this.enchantedLink, this.oauth, this.sso);
}
