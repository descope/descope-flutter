# Descope for Flutter

The Descope package for flutter provides convenient access to the
Descope user management and authentication APIs for applications written for Flutter.
You can read more on the [Descope Website](https://descope.com).

## Features

- Authenticate users using the authentication methods that suit your needs:
  - [OTP](#otp-authentication) (one-time password)
  - [TOTP](#totp-authentication) (timed one-time password / authenticator app)
  - [Magic Link](#magic-link)
  - [Enchanted Link](#enchanted-link)
  - [OAuth](#oauth) (social)
  - [SSO / SAML](#ssosaml)
  - [Passwords](#password-authentication) (unrecommended form of authentication)
- [Session Management](#session-management)

## Quickstart

A Descope `Project ID` is required to initialize the SDK. Find it
on the [project page](https://app.descope.com/settings/project) in
the Descope Console.

```dart
import 'package:descope_flutter/descope.dart';

// Where your application is being created
Descope.projectId = '<Your-Project-ID>';
```

Authenticate the user in your application by starting one of the
authentication methods. For example, let's use OTP via email:

```dart
// sends an OTP code to the given email address
await Descope.otp.signUp(method: DeliveryMethod.Email, loginId: "andy@example.com");
```

Finish the authentication by verifying the OTP code the user entered:

```dart
// if the user entered the right code the authentication is successful
final authResponse = await Descope.otp.verify(method: DeliveryMethod.Email, loginId: "andy@example.com", code: code);

// we create a DescopeSession object that represents an authenticated user session
final session = DescopeSession(authResponse);

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
as ensuring that it's refreshed when needed.

Once the user completes a sign in flow successfully you should set the
`DescopeSession` object as the active session of the session manager.

```dart
final authResponse = await Descope.otp.verify(method: DeliverMethod.Email, loginId: "andy@example.com", code: "123456");
final session = DescopeSession(authResponse);
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
    request.headers["X-Auth-Token"] = sessionJwt;
} else {
    // unauthorized
}
```

When the application is relaunched the `DescopeSessionManager` loads any
existing session automatically, so you can check straight away if there's
an authenticated user.

```dart
Descope.projectId = "...";
final session = Descope.sessionManager.session;
if (session != null) {
    print("User is logged in: $session");
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
final authResponse = await Descope.otp.verify(method: DeliveryMethod.email, loginId: "desmond_c@mail.com", code: "123456");
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
