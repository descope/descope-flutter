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
