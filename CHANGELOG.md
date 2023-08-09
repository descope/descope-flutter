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
