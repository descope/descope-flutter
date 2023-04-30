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

## Setup

A Descope `Project ID` is required to initialize the SDK. Find it on the
[project page in the Descope Console](https://app.descope.com/settings/project).

```dart
import 'package:descope_flutter/descope.dart';

// ...

final descope = DescopeSDK(projectId: '<Your-Project-ID>');
```

## Usage

Here are some examples how to manage and authenticate users:

### OTP Authentication

Send a user a one-time password (OTP) using your preferred delivery method (_email / SMS_).
An email address or phone number must be provided accordingly.

The user can either `sign up`, `sign in` or `sign up or in`

```dart
// Every user must have a loginID. All other user information is optional
final maskedEmail = await descope.otp.signUp(method: DeliveryMethod.email, loginId: 'desmond_c@mail.com',
    user: User(name: 'Desmond Copeland'));
```

The user will receive a code using the selected delivery method. Verify that code using:

```dart
final descopeSession = await descope.otp.verify(method: DeliveryMethod.email, loginId: "desmond_c@mail.com", code: "123456");
```

Read more on [session management](#session-management)

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
await descope.magicLink.signUp(method: DeliveryMethod.email, loginId: 'desmond_c@mail.com',
    user: User(name: 'Desmond Copeland'), uri: 'https://your-redirect-address.com/verify');
```

To verify a magic link, your redirect page must call the validation function
on the token (`t`) parameter (`https://your-redirect-address.com/verify?t=<token>`):

```dart
final descopeSession = await descope.magicLink.verify(token: '<token>');
```

Read more on [session management](#session-management)

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
final enchantedLinkResponse = await descope.enchantedLink.signUp(loginId: 'desmond_c@mail.com',
    user: User(name: 'Desmond Copeland'), uri: 'https://your-redirect-address.com/verify');
```

Inform the user which link is the correct one, using `enchantedLinkResponse.linkId`.
After that, start polling for a valid session. It will be returned once the user
clicks on the correct link (assuming the redirected web page calls the `validate` method);

```dart
final descopeSession = await descope.enchantedLink.pollForSession(pendingRef: enchantedLinkResponse.pendingRef);
```

Read more on [session management](#session-management)

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
final authUrl = await descope.oauth.start(provider: OAuthProvider.google, redirectUrl: 'exampleauthschema://my-app.com/handle-oauth');
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
// Exchange code for session
final descopeSession = await descope.oauth.exchange(code: code!);
```

Read more on [session management](#session-management)

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
final authUrl = await descope.sso.start(emailOrTenantId: 'my-tenant-ID', redirectUrl: 'exampleauthschema://my-app.com/handle-saml');
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
// Exchange code for session
final descopeSession = await descope.sso.exchange(code: code!);
```

Read more on [session management](#session-management)

### TOTP Authentication

The user can authenticate using an authenticator app, such as Google Authenticator.
Sign up like you would using any other authentication method. The sign up response
will then contain a QR code `image` that can be displayed to the user to scan using
their mobile device camera app, or the user can enter the `key` manually or click
on the link provided by the `provisioningURL`.

Existing users can add TOTP using the `update` function.

```dart
// Every user must have a loginID. All other user information is optional
final totpResponse = await descope.totp.signUp(loginId: 'desmond@descope.com', user: User(name: 'Desmond Copeland'));

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
final descopeSession = await descope.totp.verify(loginId: 'desmond@descope.com', code: '123456');
```

Read more on [session management](#session-management)

### Password Authentication

It is possible to authenticate a user using a password. Passwords are a legacy way of authentication.
Each of the passwordless methods above are better from a security and usability perspective.
Passwords are disabled by default in the
[Descope Console password settings](https://app.descope.com/settings/authentication/password).
Make sure to enable it before attempting authentication.
The user can either `sign up` or `sign in`

```dart
// Every user must have a loginID. All other user information is optional
final descopeSession = await descope.password.signUp(loginId: 'desmond_c@mail.com', password: 'cleartext-password',
    user: User(name: 'Desmond Copeland'));
```

Read more on [session management](#session-management)

## Session Management

After authenticating successfully, the `DescopeSession` needs to be
managed throughout the lifecycle of the application.

### Persistence

The `DescopeSession` should be persisted between usages. Do it be securely saving the
`DescopeSession.refreshJwt` and `DescopeSession.sessionJwt`.
When the app is reloaded, recreate the session using:

```dart
final descopeSession = DescopeSession('<loaded-session-jwt>', '<loaded-refresh-jwt>');
```

### Session Refresh

When the session JWT expires, it needs to be refreshed.

You can manually refresh it by calling:

```dart
final refreshedDescopeSession = await descope.auth.refreshSession(descopeSession.refreshJwt);
```

### Session Validation

Every secure request performed between your client and server needs to be validated. The client sends
the session and refresh tokens with every request, to validated by the server.

On the server side, it will validate the session and also refresh it in the event it has expired.
Every request should receive the given session token if it's still valid, or a new one if it was refreshed.
Make sure to save the returned session as it might have been refreshed.

The `refreshJwt` is optional here to validate a session, but is required
to refresh the session in the event it has expired.

Usually, the tokens can be passed in and out via HTTP headers or via a cookie.
The implementation can defer according to your server implementation.

## Additional Information

To learn more please see the [Descope Documentation and API reference page](https://docs.descope.com/).

## Contact Us

If you need help you can email [Descope Support](mailto:support@descope.com)

## License

The Descope SDK for Flutter is licensed for use under the terms and conditions
of the [MIT license Agreement](https://github.com/descope/descope-flutter/blob/main/LICENSE).
