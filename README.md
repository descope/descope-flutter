# Descope for Flutter

The Descope package for flutter provides convenient access to the
Descope user management and authentication APIs for applications written for Flutter.
You can read more on the [Descope Website](https://descope.com).

## Features

- [Quickstart](#quickstart)
- [Session Management](#session-management)
- [Custom Claims](#custom-claims)
- [Error handling](#error-handling)
- [Running Flows](#running-flows)
- Authenticate users using the authentication methods that suit your needs:
  - [OTP](#otp-authentication) (one-time password)
  - [TOTP](#totp-authentication) (timed one-time password / authenticator app)
  - [Magic Link](#magic-link)
  - [Enchanted Link](#enchanted-link)
  - [OAuth](#oauth) (social)
  - [SSO / SAML](#ssosaml)
  - [Passkeys](#passkeys)
  - [Passwords](#password-authentication)

## Quickstart

A Descope `Project ID` is required to initialize the SDK. Find it
on the [project page](https://app.descope.com/settings/project) in
the Descope Console.

```dart
import 'package:descope/descope.dart';

// Where your application state is being created
Descope.setup('<Your-Project-ID>');

// Optionally, you can configure the SDK to your needs
Descope.setup('<Your-Project-Id>', (config) {
  // set a custom base URL (needs to be set up in the Descope console)
  config.baseUrl = 'https://my.app.com';
  // enable the logger
  if (kDebugMode) {
    config.logger = DescopeLogger();
  }
});

// Load any available sessions
await Descope.sessionManager.loadSession();
```

Authenticate the user in your application by starting one of the
authentication methods. For example, let's use OTP via email:

```dart
// sends an OTP code to the given email address
await Descope.otp.signUp(method: DeliveryMethod.email, loginId: 'andy@example.com');
```

Finish the authentication by verifying the OTP code the user entered:

```dart
// if the user entered the right code the authentication is successful
final authResponse = await Descope.otp.verify(method: DeliveryMethod.email, loginId: 'andy@example.com', code: code);

// we create a DescopeSession object that represents an authenticated user session
final session = DescopeSession.fromAuthenticationResponse(authResponse);

// the session manager automatically takes care of persisting the session
// and refreshing it as needed
Descope.sessionManager.manageSession(session);
```

On the next application launch check if there's a logged in user to
decide which screen to show:

```dart
// check if we have a valid session from a previous launch and that it hasn't expired yet
if (Descope.sessionManager.session?.refreshToken?.isExpired == true) {
    // Show main UI
} else {
    // Show login UI
}
```

Use the active session to authenticate outgoing API requests to the
application's backend:

```dart
request.setAuthorization(Descope.sessionManager);
```

## Session Management

The `DescopeSessionManager` class is used to manage an authenticated
user session for an application.

The session manager takes care of loading and saving the session as well
as ensuring that it's refreshed when needed. When the user completes a sign
in flow successfully you should set the `DescopeSession` object as the
active session of the session manager.

```dart
final authResponse = await Descope.otp.verify(method: DeliverMethod.Email, loginId: 'andy@example.com', code: '123456');
final session = DescopeSession.fromAuthenticationResponse(authResponse);
Descope.sessionManager.manageSession(session);
```

The session manager can then be used at any time to ensure the session
is valid and to authenticate outgoing requests to your backend with a
bearer token authorization header.

```dart
request.setAuthorization(Descope.sessionManager);
```

If your backend uses a different authorization mechanism you can of course
use the session JWT directly instead of the extension function. You can either
add another extension function on `http.Request` such as the one above, or you
can do the following.

```dart
await Descope.sessionManager.refreshSessionIfNeeded();
final sessionJwt = Descope.sessionManager.session?.sessionJwt;
if (sessionJwt != null) {
    request.headers['X-Auth-Token'] = sessionJwt;
} else {
    // unauthorized
}
```

When the application is relaunched the `DescopeSessionManager` can load the existing
session and you can check straight away if there's an authenticated user.

```dart
await Descope.sessionManager.loadSession();
```

If you prefer to call `loadSession` in your `main()` function, before the platform's
`runApp()` function is called, then you'll need to ensure the widget bindings are
initialized first:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Descope.setup('...');
  await Descope.sessionManager.loadSession();

  final session = Descope.sessionManager.session;
  if (session != null) {
    print('User is logged in: ${session.user}');
  }

  runApp(
    ...
  );
}
```

When the user wants to sign out of the application we revoke the
active session and clear it from the session manager:

```dart
final refreshJwt = Descope.sessionManager.session?.refreshToken.jwt;
if (refreshJwt != null) {
  Descope.sessionManager.clearSession();
  try {
    Descope.auth.revokeSessions(RevokeType.currentSession, refreshJwt);
  } catch (e) {
    // handle errors
  }
}
```

It is also possible to revoke all sessions by providing the appropriate `RevokeType` parameter.

You can customize how the `DescopeSessionManager` behaves by using
your own `storage` and `lifecycle` objects. See the documentation
for more details.

## Custom Claims

You can request for a sign in operation to add additional custom claims to the
user's JWT during authentication.

For example, the following code starts an OTP sign in and requests a custom claim
with the authenticated user's full name:

```dart
const options = SignInOptions(customClaims: {'name': '{{user.name}}'});
await Descope.otp.signIn(method: DeliveryMethod.email, loginId: 'desmond_c@mail.com', options: options);
```

Note that any custom claims added via this method are considered insecure and will
be nested under the `nsec` custom claim.

## Error Handling

All authentication operations throw a `DescopeException` in case of a failure. There are several
ways to catch and handle a `DescopeException`, and you can use whichever one is more
appropriate in each specific use case.

```dart
try {
  final authResponse = await Descope.otp.verify(method: DeliveryMethod.email, loginId: loginId, code: code);
  final session = DescopeSession.fromAuthenticationResponse(authResponse);
  Descope.sessionManager.manageSession(session);
} on DescopeException catch (e) {
  switch(e) {
    case DescopeException.wrongOTPCode:
    case DescopeException.invalidRequest:
      showBadCodeAlert();
      break;
    case DescopeException.networkError:
      showNetworkErrorRetry();
      break;
    default:
      showUnexpectedErrorAlert(with: e);
  }
}
```

See the `DescopeException` class for specific error values. Note that not all API errors
are listed in the SDK yet. Please let us know via a Github issue or pull request if you
need us to add any entries to make your code simpler.

## Running Flows

**Important Note**: `DescopeFlowView` is only available on iOS and Android platforms. Other platforms can still use the [previous implementation of flows](https://github.com/descope/descope-flutter/blob/main/lib/src/sdk/routes.dart#L52) until `DescopeFlowView` is supported.

We can authenticate users by building and running Flows. Flows are built in the Descope
[flow editor](https://app.descope.com/flows). The editor allows you to easily
define both the behavior and the UI that take the user through their
authentication journey. Read more about it in the  Descope
[getting started](https://docs.descope.com/build/guides/gettingstarted/) guide.

The flow setup differs according to the targeted platforms

### Setup #1: Define and host your flow

Before we can run a mobile flow, it must first be defined and hosted. Every project
comes with predefined flows out of the box. You can customize your flows to suit your needs
and host it. Follow
the [getting started](https://docs.descope.com/build/guides/gettingstarted/) guide for more details.
You can host the flow yourself or leverage Descope's hosted flow page. Read more about it [here](https://docs.descope.com/customize/auth/oidc/#hosted-flow-application).
You can also check out the [auth-hosting repo itself](https://github.com/descope/auth-hosting).

### (OPTIONAL) Setup #2.1: Enable App Links for Magic Link and OAuth (social) on Android

Some authentication methods rely on leaving the application's context to authenticate the
user, such as navigating to an identity provider's website to perform OAuth (social) authentication,
or receiving a Magic Link via email or text message. If you do not intend to use these authentication
methods, you can skip this step. Otherwise, in order for the user to get back
to your application, setting up [App Links](https://developer.android.com/training/app-links#android-app-links) is required.
Once you have a domain set up and [verified](https://developer.android.com/training/app-links/verify-android-applinks) for sending App Links,
you'll need to handle the incoming deep links in your app, and resume the flow.

### (OPTIONAL) Setup #2.2: Support Magic Link Redirects on iOS

Supporting Magic Link authentication in flows requires some platform specific setup:
You'll need to [support associated domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains?language=swift).
It is recommended to follow the [Flutter guide to deep linking](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links) for the basic setup or use an equivalent library.

Regardless of the platform, another path is required to handle magic link redirects specifically. For the sake of this README, let's name
it `/magiclink`. It is possible to set up multiple paths if needed, in exactly the same way.

### Provide a controller when setting up the DescopeFlowView
The `DescopeFlowController` is used to mainly use to call functions on the flow view,
namely the `resumeFromDeepLink` function to resume a flow after returning from a magic link or social authentication.
All app architectures are different, so it's up to you to decide where to store the controller.
Here's a simple example of storing it in the app's state:
```dart
class AppModel extends ChangeNotifier {
  final DescopeFlowController _descopeFlowController = DescopeFlowController();

  DescopeFlowController get descopeFlowController => _descopeFlowController;

  void handleFlowDeepLink(Uri uri) {
    _descopeFlowController.resumeFromDeepLink(uri);
  }
}
```

### Define a route to handle the App Link sent at the end of a flow
_this code example demonstrates how app links should be handled - you can customize it to fit your app_
```dart
// There are various way to listen for deep links in Flutter. This example does not assume any specific
// routing package, and focuses on the deep link handling itself.
final _handleIncomingLinks = (Uri uri) {
  if (uri.path == '/magiclink' || uri.path == '/oauth') { // This path needs to correspond to the deep link you configured in your manifest or associated domain - see below
    try {
      model.handleFlowDeepLink(uri);
    } catch (e) {
      // Handle errors here
    }
  }
};
```
### Setup #3: Validate everything works
If deep links are required for your flows, it is recommended to validate that deep linking has been set up correctly.
You can do that by running the app on a real device, and sending an app link to, for example, your email address.
Clicking the link should open the app. If it does not, please review your setup and try again.

### Run a Flow

After completing the prerequisite steps, it is now possible to run a flow.
The flow will run in a dedicated `DescopeFlowView` widget which receives:
- `DescopeFlowConfiguration` - defines all of the options available when running a flow on both
  Android and iOS. Read the class documentation for a detailed explanation.
- `DescopeFlowCallbacks` - the callbacks or the main method the flow communicates with the hosting app.
    handle `ready`, `success` and `error` events as makes sense for your app.
- `DescopeFlowController` - used to control the flow view, mainly resuming from deep links. If no deep links
  are expected, this can be omitted.

All of these classes have detailed documentation. It is recommended to read them for a deeper understanding of
how to use them.

There are truly many ways to integrate the flow view into your app. Here's a very simple example of
a screen containing a `DescopeFlowView` with minimal configuration:
```dart
class _NativeFlowScreenState extends State<NativeFlowScreen> {
  bool _loading = true;

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Descope Flow View Example'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
          tooltip: 'Close',
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Solid background to avoid black flash
            Positioned.fill(child: ColoredBox(color: bg)),
            // Keep the platform view mounted but invisible until ready
            Positioned.fill(
              child: AnimatedOpacity(
                opacity: _loading ? 0.0 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: DescopeFlowView(
                  config: DescopeFlowConfig(
                    url: '<URL for where the flow is hosted, for example: https://api.descope.com/login/[MY_PROJECT_ID]?flow=[MY_FLOW_ID]>',
                    // Optional parameters - will be required according to the flow you're using
                    // and the authentication methods it contains
                    androidOAuthNativeProvider: 'google', // an example supporting native Google Sign In on Android
                    iosOAuthNativeProvider: 'apple', // an example supporting native Sign In with Apple on iOS
                    oauthRedirect: 'https://YOUR_DEEP_LINK_URL/oauth', // android only - needs to match the app link you configured in your manifest
                    magicLinkRedirect: 'https://YOUR_DEEP_LINK_URL/magiclink', // needs to match the app link you configured in your manifest or associated domain
                  ),
                  callbacks: DescopeFlowCallbacks(
                    onReady: () {
                      // simple reveal animation when the flow is ready
                      if (!mounted) return;
                      setState(() => _loading = false);
                    },
                    onSuccess: (AuthenticationResponse res) {
                      // handle the successful authentication response, assuming the model calls
                      // something along the lines of:
                      // final session = DescopeSession.fromAuthenticationResponse(res);
                      // Descope.sessionManager.manageSession(session);
                      model.handleAuthResponse(res);
                      if (context.mounted) context.pop();
                    },
                    onError: (DescopeException e) {
                      // handle any errors that might occur during the flow.
                      // errors generally mean that the flow is unrecoverable and
                      // needs to be restarted.
                      model.handleError(e);
                      if (context.mounted) context.pop();
                    },
                  ),
                  controller: model.descopeFlowController,
                ),
              ),
            ),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
```

## Authentication Methods

We can authenticate users by using any combination of the authentication methods
supported by this SDK.
Here are some examples for how to authenticate users:

### OTP Authentication

Send a user a one-time password (OTP) using your preferred delivery method (_email / SMS_).
An email address or phone number must be provided accordingly.

The user can either `sign up`, `sign in` or `sign up or in`

```dart
// Every user must have a loginID. All other user information is optional
final maskedEmail = await Descope.otp.signUp(method: DeliveryMethod.email, loginId: 'desmond_c@mail.com',
    details: SignUpDetails(name: 'Desmond Copeland'));
```

The user will receive a code using the selected delivery method. Verify that code using:

```dart
final authResponse = await Descope.otp.verify(method: DeliveryMethod.email, loginId: 'desmond_c@mail.com', code: '123456');
```

### Magic Link

Send a user a Magic Link using your preferred delivery method (_email / SMS_).
The Magic Link will redirect the user to a page where the attached token needs to be verified. Depending on the target,
it might be required to use **deep links** to return to the app.
This redirection can be configured in code, or globally in
the [Descope Console](https://app.descope.com/settings/authentication/magicLink)

The user can either `sign up`, `sign in` or `sign up or in`

```dart
// If configured globally, the redirect URL is optional. If provided however, it will be used
// instead of any global configuration
await Descope.magicLink.signUp(method: DeliveryMethod.email, loginId: 'desmond_c@mail.com',
    details: SignUpDetails(name: 'Desmond Copeland'), redirectUrl: 'https://your-redirect-address.com/verify');
```

To verify a magic link, your redirect page must call the validation function
on the token (`t`) parameter (`https://your-redirect-address.com/verify?t=<token>`):

```dart
final authResponse = await Descope.magicLink.verify(token: '<token>');
```

### Enchanted Link

Using the Enchanted Link APIs enables users to sign in by clicking a link
delivered to their email address. The email will include 3 different links,
and the user will have to click the right one, based on the 2-digit number that is
displayed when initiating the authentication process.

This method is similar to [Magic Link](#magic-link) but differs in two major ways:

- The user must choose the correct link out of the three, instead of having just one
  single link.
- This supports cross-device clicking, meaning the user can try to log in on one device,
  like a computer, while clicking the link on another device, for instance a mobile phone.

The Enchanted Link will redirect the user to page where the its token needs to be verified.
This redirection can be configured in code per request, or set globally in
the [Descope Console](https://app.descope.com/settings/authentication/enchantedlink).

The user can either `sign up`, `sign in` or `sign up or in`

```dart
// If configured globally, the redirect URL is optional. If provided however, it will be used
// instead of any global configuration
final enchantedLinkResponse = await Descope.enchantedLink.signUp(loginId: 'desmond_c@mail.com',
    details: SignUpDetails(name: 'Desmond Copeland'), redirectUrl: 'https://your-redirect-address.com/verify');
```

Inform the user which link is the correct one, using `enchantedLinkResponse.linkId`.
After that, start polling for a valid session. It will be returned once the user
clicks on the correct link (assuming the redirected web page calls the `validate` method);

```dart
final authResponse = await Descope.enchantedLink.pollForSession(pendingRef: enchantedLinkResponse.pendingRef);
```

### OAuth

Users can authenticate using their social logins, using the OAuth protocol.
Configure your OAuth settings on the [Descope console](https://app.descope.com/settings/authentication/social).
It is recommended to use [flutter_web_auth](https://pub.dev/packages/flutter_web_auth)
to handle the redirect and code extraction.

To start a flow call:

```dart
import 'package:flutter_web_auth/flutter_web_auth.dart';

// Choose an oauth provider out of the supported providers
// If configured globally, the redirect URL is optional. If provided however, it will be used
// instead of any global configuration.
final authUrl = await Descope.oauth.start(provider: OAuthProvider.google, redirectUrl: 'exampleauthschema://my-app.com/handle-oauth');
```

Take the generated URL and authenticate the user using `flutter_web_auth`
(read more [here](https://pub.dev/packages/flutter_web_auth)).
The user will authenticate with the authentication provider, and will be
redirected back to the redirect URL, with an appended `code` HTTP URL parameter.
Exchange it to validate the user:

```dart
// Redirect the user to the returned URL to start the OAuth redirect chain
final result = await FlutterWebAuth.authenticate(url: authUrl, callbackUrlScheme: 'exampleauthschema');
// Extract the returned code
final code = Uri.parse(result).queryParameters['code'];
// Exchange code for an authentication response
final authResponse = await Descope.oauth.exchange(code: code!);
```

When running in iOS or Android, you can leverage the [Sign in with Apple](https://developer.apple.com/sign-in-with-apple)
and [Sign in with Google](https://developer.android.com/training/sign-in/credential-manager)
features to show a native authentication view that allows the user to login using the account
they are already logged into on their device. Note that your application will need some
configuration to support native authentication. See the function documentation for
more details.

```dart
void loginWithOAuth() async {
  AuthenticationResponse response;
  if (!kIsWeb && Platform.isIOS) {
    // created a custom Apple provider using the app bundle identifier as the Client ID
    response = await Descope.oauth.native(provider: OAuthProvider.named("ios"));
  } else if (!kIsWeb && Platform.isAndroid) {
    // created a custom Google provider for implicit authentication
    response = await Descope.oauth.native(provider: OAuthProvider.named("android"));
  } else {
    // regular web OAuth
  }
  final session = DescopeSession.fromAuthenticationResponse(response)
  // ...
}
```

### SSO/SAML

Users can authenticate to a specific tenant using SAML or Single Sign On.
Configure your SSO/SAML settings on the [Descope console](https://app.descope.com/settings/authentication/sso).
It is recommended to use [flutter_web_auth](https://pub.dev/packages/flutter_web_auth)
to handle the redirect and code extraction.

To start a flow call:

```dart
// Choose which tenant to log into
// If configured globally, the return URL is optional. If provided however, it will be used
// instead of any global configuration.
final authUrl = await Descope.sso.start(emailOrTenantId: 'my-tenant-ID', redirectUrl: 'exampleauthschema://my-app.com/handle-saml');
```

Take the generated URL and authenticate the user using `flutter_web_auth`
(read more [here](https://pub.dev/packages/flutter_web_auth)).
The user will authenticate with the authentication provider, and will be
redirected back to the redirect URL, with an appended `code` HTTP URL parameter.
Exchange it to validate the user:

```dart
// Redirect the user to the returned URL to start the OAuth redirect chain
final result = await FlutterWebAuth.authenticate(url: authUrl, callbackUrlScheme: 'exampleauthschema');
// Extract the returned code
final code = Uri.parse(result).queryParameters['code'];
// Exchange code for an authentication response
final authResponse = await Descope.sso.exchange(code: code!);
```

### Passkeys

Users can authenticate by creating or using a [passkey](https://fidoalliance.org/passkeys/).
Configure your Passkey/WebAuthn settings on the [Descope console](https://app.descope.com/settings/authentication/webauthn).
Make sure it is enabled and that the top level domain is configured correctly.

After that, for iOS go through Apple's [Supporting passkeys](https://developer.apple.com/documentation/authenticationservices/public-private_key_authentication/supporting_passkeys/)
guide, in particular be sure to have an associated domain configured for your app
with the `webcredentials` service type, whose value matches the top level domain
you configured in the Descope console earlier. 
For Android, please follow the [Add support for Digital Asset Links](https://developer.android.com/training/sign-in/passkeys#add-support-dal)
setup, as described in the official Google docs.

```dart
try {
    showLoading(true);
    final authResponse = await Descope.passkey.signUpOrIn(loginId: loginId);
    final session = DescopeSession.fromAuthenticationResponse(authResponse);
    Descope.sessionManager.manageSession(session);
    showHomeScreen() 
} on DescopeException catch (e) {
    if (e == DescopeException.passkeyCancelled) {
      showLoading(false)
      print("Authentication cancelled")
    } else {
      showError(error)
    }
}
```

### TOTP Authentication

The user can authenticate using an authenticator app, such as Google Authenticator.
Sign up like you would using any other authentication method. The sign up response
will then contain a QR code `image` that can be displayed to the user to scan using
their mobile device camera app, or the user can enter the `key` manually or click
on the link provided by the `provisioningURL`.

Existing users can add TOTP using the `update` function.

```dart
// Every user must have a loginID. All other user information is optional
final totpResponse = await Descope.totp.signUp(loginId: 'desmond@descope.com', details: SignUpDetails(name: 'Desmond Copeland'));

// Use one of the provided options to have the user add their credentials to the authenticator
// totpResponse.provisioningUrl
// totpResponse.image
// totpResponse.key
```

There are 3 different ways to allow the user to save their credentials in
their authenticator app - either by clicking the provisioning URL, scanning the QR
image or inserting the key manually. After that, signing in is done using the code
the app produces.

```dart
final authResponse = await Descope.totp.verify(loginId: 'desmond@descope.com', code: '123456');
```

### Password Authentication

It is possible to authenticate a user using a password. Passwords are a legacy way of authentication.
Each of the passwordless methods above are better from a security and usability perspective.
Passwords are disabled by default in the
[Descope Console password settings](https://app.descope.com/settings/authentication/password).
Make sure to enable it before attempting authentication.
The user can either `sign up` or `sign in`

```dart
// Every user must have a loginID. All other user information is optional
final authResponse = await Descope.password.signUp(loginId: 'desmond_c@mail.com', password: 'cleartext-password',
    details: SignUpDetails(name: 'Desmond Copeland'));
```

#### Update or Replace Password

```dart
// It's possible to update a user's password when the user has an active session:
await Descope.password.update(loginId: 'andy@example.com', newPassword: 'newSecurePassword456!', refreshJwt: "user-refresh-jwt");

// Or to replace a user's password by providing their current password.
// this is especially true when a password expires:
final authResponse = await Descope.password.replace(loginId: 'andy@example.com', oldPassword: 'SecurePassword123!', newPassword: 'NewSecurePassword456!');
```

#### Send Password Reset Email

Initiate a password reset (update) by sending a magic link email, that needs to be validated
like any other magic link. After authenticating the user using this magic link, it's
possible to use the `update` function to update the user's password:

```dart
await Descope.password.sendReset(loginId: 'andy@example.com', redirectUrl: "exampleauthschema://my-app.com/handle-reset");
```

## Additional Information

To learn more please see the [Descope Documentation and API reference page](https://docs.descope.com/).

## Contact Us

If you need help you can email [Descope Support](mailto:support@descope.com)

## License

The Descope SDK for Flutter is licensed for use under the terms and conditions
of the [MIT license Agreement](https://github.com/descope/descope-flutter/blob/main/LICENSE).
