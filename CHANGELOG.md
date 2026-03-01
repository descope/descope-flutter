# 0.9.15

- Fix web component CDN URL to load browser-compatible bundle for versions >= 3.9.0
- Migrate from deprecated `package:js` to `dart:js_interop`
- Minimum Dart and Flutter versions raised to 3.1.0 and 3.13.0 respectively

# 0.9.14

- Bump Component version to 3.56.0 for Flutter web flows

# 0.9.13

- Update Descope iOS native SDK

# 0.9.12

- Stream native (iOS/Android) logs to the Flutter `DescopeLogger`
- **Breaking Change**: Renamed `DescopeLogger` properties to `level` and `unsafe`

# 0.9.11
- Support links in iOS native flows
- Support `mailto:` links everywhere

# 0.9.10
- Update Descope native SDKs

# 0.9.9

- Introducing the `DescopeFlowView` widget for seamless integration of Descope Flows in Flutter applications. Available for both Android and iOS platforms.
- `DescopeFlow` is now deprecated in favor of `DescopeFlowView`, however, it is still available for backward compatibility, and for non-mobile platforms like web.

# 0.9.8

- Support external token in `AuthenticationResponse`

# 0.9.7

- Fix user deserialization

# 0.9.6

- Add more fields to the `DescopeUser`

# 0.9.5

- Migrate Android passkey implementation to use `CredentialManager` instead of `Fido2`

# 0.9.4

- Add the ability to explicitly check if passkeys are supported on the device

# 0.9.3

- Fix issue with passkey userId encoding/decoding

# 0.9.2

- Add exception parsing from server response

# 0.9.1

- Support passkeys in Flutter Web

# 0.9.0

- New setup function for initializing the Descope SDK
- Replace password now returns a `AuthenticationResponse`
- Flutter Web support for both Session Management and Flows

# 0.8.1

- Remove OAuth `clientId` validation in iOS plugin

# 0.8.0

- Add custom attributes and multiple names to DescopeUser objects
- Add support for native Sign in with Apple/Google authentication
- Add support for authentication with Passkeys

# 0.7.2

- Fix issue with parsing cookie headers

# 0.7.1

- Add support for custom OAuth providers

# 0.7.0

- Added Magic Link support to Flows
- New `DescopeException` now thrown from all operations
- Fixed `redirectUrl` parameter
- Added Logger & Network client for easier debugging

# 0.6.0

- Beta release. 
- `README.md` updated to convey all changes.

## New Features

- The new `Descope` convenience class wraps around the `DescopeSdk` and provides easier access for most cases. Alternatively `DescopeSdk` instances can still be created. 
- Manage your session using the new `DescopeSessionManager`. Sessions are saved securely on Android and iOS.
- Authenticate using [Flows](https://app.descope.com/flows).
- Added `http.Request` authorization extensions.
- Added `createdTime` to `UserResponse`.

## Breaking Changes

- Authentication methods no longer return a session directly, but rather the new `AuthenticationResponse`. It can be converted into a `DescopeSession` by calling `DescopeSession.fromAuthenticationResponse(authResponse)`.
- `DescopeSDK` renamed to `DescopeSdk`.
- `refreshSession()`  now returns `RefreshResponse` instead of `DescopeSession`.
- `DescopeConfig` constructor changed.
- `User` renamed to `SignUpDetials`.
- `me` request now returns a `DescopeUser` instead of `MeResponse` which has been deleted.

# 0.5.1

- Fixed publish workflow

# 0.5.0

- Initial alpha release
