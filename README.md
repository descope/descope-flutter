# Descope for Flutter

The Descope package for flutter provides convenient access to the
Descope user management and authentication APIs for applications written for Flutter.
You can read more on the [Descope Website](https://descope.com).

## Features

- [Quickstart](#quickstart)
- [Session Management](#session-management)
- [Authentication Flows](#running-flows)
- Authenticate users using the authentication methods that suit your needs:
  - [OTP](#otp-authentication) (one-time password)
  - [TOTP](#totp-authentication) (timed one-time password / authenticator app)
  - [Magic Link](#magic-link)
  - [Enchanted Link](#enchanted-link)
  - [OAuth](#oauth) (social)
  - [SSO / SAML](#ssosaml)
  - [Passwords](#password-authentication) (unrecommended form of authentication)

## Quickstart

A Descope `Project ID` is required to initialize the SDK. Find it
on the [project page](https://app.descope.com/settings/project) in
the Descope Console.

```dart
import 'package:descope/descope.dart';

// Where your application state is being created
Descope.projectId = '<Your-Project-ID>';
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

  Descope.projectId = '...';
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
final refreshJwt = Descope.sessionManager.session?.refreshJwt;
if (refreshJwt != null) {
  Descope.auth.logout(refreshJwt);
  Descope.sessionManager.clearSession();
}
```

You can customize how the `DescopeSessionManager` behaves by using
your own `storage` and `lifecycle` objects. See the documentation
for more details.

## Running Flows

We can authenticate users by building and running Flows. Flows are built in the Descope
[flow editor](https://app.descope.com/flows). The editor allows you to easily
define both the behavior and the UI that take the user through their
authentication journey. Read more about it in the  Descope
[getting started](https://docs.descope.com/build/guides/gettingstarted/) guide.

### Setup #1: Define and host your flow

Before we can run a flow, it must first be defined and hosted. Every project
comes with predefined flows out of the box. You can customize your flows to suit your needs
and host it. Follow
the [getting started](https://docs.descope.com/build/guides/gettingstarted/) guide for more details.
You can host the flow yourself or leverage Descope's hosted flow page. Read more about it [here](https://docs.descope.com/customize/auth/oidc/#hosted-flow-application).
You can also check out the [auth-hosting repo itself](https://github.com/descope/auth-hosting).

### (Android Only) Setup #2: Enable App Links

Running a flow via the Flutter SDK, when targeting Android, requires setting up [App Links](https://developer.android.com/training/app-links#android-app-links).
This is essential for the SDK to be notified when the user has successfully
authenticated using a flow. Once you have a domain set up and
[verified](https://developer.android.com/training/app-links/verify-android-applinks)
for sending App Links, you'll need to handle the incoming deep links in your app:

#### Define a route to handle the App Link sent at the end of a flow
_this code example demonstrates how app links should be handled - you can customize it to fit your app_
```dart
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const MyHomePage(title: 'Flutter Demo Home Page'), // Your main app
      routes: [
        GoRoute(
          path: 'auth', // This path needs to correspond to the deep link you configured in your manifest - see below
          redirect: (context, state) async {
            try {
              Descope.flow.exchange(state.uri); // Call exchange to complete the flow
            } catch (e) {
              // Handle errors here
            }
            return '/'; // This route doesn't display anything but returns the root path where the user will be signed in
          },
        ),
        // Magic Link handling will be here. See the documentation below.
      ],
    ),
  ],
);
```

#### Add a matching Manifest declaration
Read more about the flutter specific `meta-data` tag mentioned here in the [official documentation](https://docs.flutter.dev/ui/navigation/deep-linking).
```xml
<activity
        android:name=".MainActivity"
        android:exported="true"
        android:launchMode="singleTask"
        android:theme="@style/LaunchTheme"
        android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
        android:hardwareAccelerated="true"
        android:windowSoftInputMode="adjustResize"> <!-- exported, singleTop are enabled by default but singleTask is required for the magic links to work -->
        
    <!-- add the following at the end of the activity tag, after anything you have defined currently -->
    
    <meta-data android:name="flutter_deeplinking_enabled" android:value="true" />
    <intent-filter android:autoVerify="true"> <!-- autoVerify required for app links -->
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.DEFAULT" />
        <category android:name="android.intent.category.BROWSABLE" />
        <!-- replace with your host, the path can change must must be reflected when running the flow -->
        <!-- the path should correspond with the routing path defined above -->
        <data android:scheme="https" android:host="<YOUR_HOST_HERE>" android:path="/auth" />
        <!-- see magic link setup below for more details -->
        <data android:scheme="https" android:host="<YOUR_HOST_HERE>" android:path="/magiclink" />
    </intent-filter>
</activity>
```

### (OPTIONAL) Setup #3: Support Magic Link Redirects

Supporting Magic Link authentication in flows requires some platform specific setup:
- On Android: add another path entry to the [App Links](https://developer.android.com/training/app-links#android-app-links).
  This is essentially another path in the same as the app link from the [previous setup step](#setup-2-enable-app-links),
  with different handling logic. Refer to the previous section for the manifest setup.
- On iOS: You'll need to [support associated domains](https://developer.apple.com/documentation/xcode/supporting-associated-domains?language=swift)
  It is recommended to follow the [Flutter guide to deep linking](https://docs.flutter.dev/cookbook/navigation/set-up-universal-links) for the basic setup.

Regardless of the platform, another path is required to handle magic link redirects specifically. For the sake of this README, let's name
it `/magiclink`

#### Define a route to handle the App Link or Universal Link sent when a magic link is sent
_this code example demonstrates how app links or universal links should be handled - you can customize it to fit your app_
```dart
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => const MyHomePage(title: 'Flutter Demo Home Page'),
      routes: [
        GoRoute(
          path: 'auth',
          redirect: (context, state) {
            try {
              Descope.flow.exchange(state.uri);
            } catch (e) {
              // Handle errors here
            }
            return '/';
          },
        ),
        // Adding the magic link handling here:
        GoRoute(
          path: 'magiclink', // This path needs to correspond to the deep link you configured in your manifest or associated domain - see below
          redirect: (context, state) async {
            try {
              await Descope.flow.resume(state.uri); // Resume the flow after returning from a magic link
            } catch (e) {
              // Handle errors here
            }
            return '/'; // This route doesn't display anything but returns the root path where the user will be signed in
          },
        ),
      ],
    ),
  ],
);
```

### Run a Flow

After completing the prerequisite steps, it is now possible to run a flow.
The flow will run in a Chrome [Custom Tab](https://developer.chrome.com/docs/android/custom-tabs/) on Android,
or via [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) on iOS.
Run the flow by calling the flow start function:

```dart
final authResponse = await Descope.flow.start('<URL_FOR_FLOW_IN_SETUP_#1>', deepLinkUrl: '<URL_FOR_APP_LINK_IN_SETUP_#2>');
final session = DescopeSession.fromAuthenticationResponse(authResponse);
Descope.sessionManager.manageSession(session);
```

When running on iOS nothing else is required. When running on Android, `Descope.flow.exchange()` function must be called.
See the [app link setup](#-android-only--setup-2--enable-app-links) for more details.

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
    user: User(name: 'Desmond Copeland'));
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
// If configured globally, the redirect URI is optional. If provided however, it will be used
// instead of any global configuration
await Descope.magicLink.signUp(method: DeliveryMethod.email, loginId: 'desmond_c@mail.com',
    user: User(name: 'Desmond Copeland'), uri: 'https://your-redirect-address.com/verify');
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
// If configured globally, the redirect URI is optional. If provided however, it will be used
// instead of any global configuration
final enchantedLinkResponse = await Descope.enchantedLink.signUp(loginId: 'desmond_c@mail.com',
    user: User(name: 'Desmond Copeland'), uri: 'https://your-redirect-address.com/verify');
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

### TOTP Authentication

The user can authenticate using an authenticator app, such as Google Authenticator.
Sign up like you would using any other authentication method. The sign up response
will then contain a QR code `image` that can be displayed to the user to scan using
their mobile device camera app, or the user can enter the `key` manually or click
on the link provided by the `provisioningURL`.

Existing users can add TOTP using the `update` function.

```dart
// Every user must have a loginID. All other user information is optional
final totpResponse = await Descope.totp.signUp(loginId: 'desmond@descope.com', user: User(name: 'Desmond Copeland'));

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
    user: User(name: 'Desmond Copeland'));
```

## Additional Information

To learn more please see the [Descope Documentation and API reference page](https://docs.descope.com/).

## Contact Us

If you need help you can email [Descope Support](mailto:support@descope.com)

## License

The Descope SDK for Flutter is licensed for use under the terms and conditions
of the [MIT license Agreement](https://github.com/descope/descope-flutter/blob/main/LICENSE).
