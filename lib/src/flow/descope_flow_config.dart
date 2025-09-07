
/// Provide configurations when embedding a FlowView into your app
class DescopeFlowConfig {
  /// The URL where the flow is hosted
  String url;
  /// The ID of the oauth provider that is configured to natively "Sign In with Google".
  /// Will likely be "google" if the Descope "Google" provider was customized,
  /// or alternatively a custom provider ID.
  String? androidOAuthNativeProvider;
  /// The ID of the oauth provider that is configured to natively "Sign In with Apple".
  /// Will likely be "apple" if the Descope "Apple" provider was customized,
  /// or alternatively a custom provider ID.
  String? iosOAuthNativeProvider;
  /// (_Android Only_) An optional deep link link URL to use when performing OAuth authentication, overriding
  /// whatever is configured in the flow or project.
  /// - **IMPORTANT NOTE**: even though App Links are the recommended way to configure
  /// deep links, some browsers, such as Opera, do not respect them and open the URLs inline.
  /// It is possible to circumvent this issue by providing a custom scheme based URL via [oauthRedirectCustomScheme].
  String? oauthRedirect;
  /// (_Android Only_) An optional custom scheme based URL, e.g. `mycustomscheme://myhost`,
  /// to use when performing OAuth authentication overriding whatever is configured in the flow or project.
  /// Functionally, this URL is exactly the same as [oauthRedirect], and will be used in its stead, only
  /// when the user has a default browser that does not honor App Links by default.
  /// That means the `https` based App Links are opened inline in the browser, instead
  /// of being handled by the application.
  String? oauthRedirectCustomScheme;
  /// (_Android Only_) An optional deep link link URL to use performing SSO authentication, overriding
  /// whatever is configured in the flow or project
  /// - **IMPORTANT NOTE**: even though App Links are the recommended way to configure
  /// deep links, some browsers, such as Opera, do not respect them and open the URLs inline.
  /// It is possible to circumvent this issue by providing a custom scheme via [ssoRedirectCustomScheme]
  String? ssoRedirect;
  /// (_Android Only_) An optional custom scheme based URL, e.g. `mycustomscheme://myhost`,
  /// to use when performing SSO authentication overriding whatever is configured in the flow or project.
  /// Functionally, this URL is exactly the same as [ssoRedirect], and will be used in its stead, only
  /// when the user has a default browser that does not honor App Links by default.
  /// That means the `https` based App Links are opened inline in the browser, instead
  /// of being handled by the application.
  String? ssoRedirectCustomScheme;
  /// An optional deep link link URL to use when sending magic link emails or SMS messages,
  /// overriding whatever is configured in the flow or project
  String? magicLinkRedirect;

  DescopeFlowConfig({required this.url, this.androidOAuthNativeProvider, this.iosOAuthNativeProvider, this.oauthRedirect, this.oauthRedirectCustomScheme, this.ssoRedirect, this.ssoRedirectCustomScheme, this.magicLinkRedirect});
}
