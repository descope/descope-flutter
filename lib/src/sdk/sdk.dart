import '/src/internal/http/descope_client.dart';
import '/src/internal/routes/auth.dart';
import '/src/internal/routes/enchanted_link.dart';
import '/src/internal/routes/magic_link.dart';
import '/src/internal/routes/oauth.dart';
import '/src/internal/routes/otp.dart';
import '/src/internal/routes/password.dart';
import '/src/internal/routes/sso.dart';
import '/src/internal/routes/totp.dart';
import '/src/internal/routes/flow.dart';
import '/src/session/lifecycle.dart';
import '/src/session/manager.dart';
import '/src/session/storage.dart';
import 'config.dart';
import 'routes.dart';

/// Provides functions for working with the Descope API.
class DescopeSdk {
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

  /// Authentication with passwords
  final DescopePassword password;

  // defer initialization to allow setting a custom manager without loading the current state
  DescopeSessionManager? _sessionManager;

  DescopeSessionManager get sessionManager => _sessionManager ?? _initDefaultManager();

  set sessionManager(DescopeSessionManager manager) => _sessionManager = manager;

  DescopeSessionManager _initDefaultManager() {
    final manager = DescopeSessionManager(SessionStorage(projectId: config.projectId), SessionLifecycle(auth));
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
    return DescopeSdk._internal(config, Flow(client), Auth(client), Otp(client), Totp(client), Password(client), MagicLink(client), EnchantedLink(client), OAuth(client), Sso(client));
  }

  DescopeSdk._internal(this.config, this.flow, this.auth, this.otp, this.totp, this.password, this.magicLink, this.enchantedLink, this.oauth, this.sso);
}
