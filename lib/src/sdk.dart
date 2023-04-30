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

/// Provides functions for working with the Descope API.
class DescopeSDK {
  /// The configuration of the [DescopeSDK] instance.
  final DescopeConfig config;

  /// General functions
  final DescopeAuth auth;

  /// Authentication with one time codes
  final DescopeOtp otp;

  /// Authentication with TOTP
  final DescopeTotp totp;

  /// Authentication with passwords
  final DescopePassword password;

  /// Authentication with magic links
  final DescopeMagicLink magicLink;

  /// Authentication with enchanted links
  final DescopeEnchantedLink enchantedLink;

  /// Authentication with OAuth
  final DescopeOAuth oauth;

  /// Authentication with SSO
  final DescopeSso sso;

  /// Creates a new [DescopeSDK] instance with the given configuration.
  ///
  /// The [projectId] of the Descope project can be found in the project page in
  /// the Descope console. The [baseUrl] is an  optional override for the URL of
  /// the Descope server, in case you need to access it through a CNAME record.
  factory DescopeSDK({
    required String projectId,
    String baseUrl = defaultBaseUrl,
  }) {
    var config = DescopeConfig(projectId, baseUrl);
    var client = DescopeClient(config);
    return DescopeSDK._internal(config, Auth(client), Otp(client), Totp(client), Password(client), MagicLink(client), EnchantedLink(client), OAuth(client), Sso(client));
  }

  DescopeSDK._internal(this.config, this.auth, this.otp, this.totp, this.password, this.magicLink, this.enchantedLink, this.oauth, this.sso);
}
