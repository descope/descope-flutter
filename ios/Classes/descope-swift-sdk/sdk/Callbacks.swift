// Generated using Sourcery 2.3.0 — https://github.com/krzysztofzablocki/Sourcery
// DO NOT EDIT

// Regenerate by running:
//     brew install sourcery
//     sourcery --parseDocumentation --sources src/sdk/Routes.swift --templates src/sdk/Callbacks.stencil --output src/sdk/Callbacks.swift

// Convenience functions for working with completion handlers.

import Foundation

public extension DescopeAccessKey {
    /// Exchanges an access key for a ``DescopeToken`` that can be used to perform
    /// authenticated requests.
    /// 
    /// - Parameter accessKey: the access key's clear text
    /// 
    /// - Returns: A ``DescopeToken`` upon successful exchange.
    func exchange(accessKey: String, completion: @escaping @Sendable (Result<DescopeToken, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await exchange(accessKey: accessKey)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeAuth {
    /// Returns details about the user. The user must have an active ``DescopeSession``.
    /// 
    /// - Parameter refreshJwt: the `refreshJwt` from an active ``DescopeSession``.
    /// 
    /// - Returns: A ``DescopeUser`` object with the user details.
    func me(refreshJwt: String, completion: @escaping @Sendable (Result<DescopeUser, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await me(refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Returns the current session user tenants.
    /// 
    /// - Parameters:
    ///   - dct: Set this to `true` and leave `tenantIds` empty to request the current
    ///     tenant for the user as set in the `dct` claim. This will fail if a tenant
    ///     hasn't already been selected.
    ///   - tenantIds: Provide a non-empty array of tenant IDs and set `dct` to `false`
    ///     to request a specific list of tenants for the user.
    ///   - refreshJwt: the `refreshJwt` from an active ``DescopeSession``.
    /// 
    /// - Returns: A list of one or more ``DescopeTenant`` values.
    func tenants(dct: Bool, tenantIds: [String], refreshJwt: String, completion: @escaping @Sendable (Result<[DescopeTenant], DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await tenants(dct: dct, tenantIds: tenantIds, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Refreshes a ``DescopeSession``.
    /// 
    /// This can be called at any time as long as the `refreshJwt` is still valid.
    /// Typically called when the `sessionJwt` is expired or is about to expire.
    /// 
    /// - Important: It's recommended to let a ``DescopeSessionManager`` object manage
    ///     sessions, in which case you can just call `refreshSessionIfNeeded` on the
    ///     manager instead to refresh and update the session. You can also use the
    ///     extension function on `URLRequest` to set the authorization header on a
    ///     request, as it will ensure that the session is valid automatically.
    /// 
    /// - Parameter refreshJwt: the `refreshJwt` from an active ``DescopeSession``.
    /// 
    /// - Returns: A new ``RefreshResponse`` with a refreshed `sessionJwt`.
    func refreshSession(refreshJwt: String, completion: @escaping @Sendable (Result<RefreshResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await refreshSession(refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Migrates an external token to a ``DescopeSession``.
    /// 
    /// This function migrates an active user authentication that was done with a different
    /// authentication provider so it can be used with Descope, thereby allowing the user
    /// to continue using the app without requiring them to sign in again or otherwise
    /// notice any change in behavior.
    /// 
    /// ```swift
    /// func migrateUserAuthentication() async throws {
    ///     // assume we have an active login from an authentication that was done with another auth provider
    ///     guard let externalToken = otherAuthProvider.authToken else { return }
    /// 
    ///     // exchange the external token and get a Descope authentication in return
    ///     let authResponse = try await Descope.auth.migrateSession(externalToken: externalToken)
    /// 
    ///     // we now have an AuthenticationResponse as if the user went through a Descope sign in call
    ///     let session = DescopeSession(from: authResponse)
    ///     Descope.sessionManager.manageSession(session)
    /// }
    /// ```
    /// 
    /// This function is only available if the Descope console was configured to allow
    /// external tokens, otherwise the call will fail.
    /// 
    /// - Parameter externalToken: the external token to migrate.
    /// 
    /// - Returns: A new ``AuthenticationResponse`` if the migration was successful.
    func migrateSession(externalToken: String, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await migrateSession(externalToken: externalToken)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Revokes active sessions for the user.
    /// 
    /// It's a good security practice to remove refresh JWTs from the Descope servers if
    /// they become redundant before expiry. This function will usually be called with `.currentSession`
    /// when the user wants to sign out of the application. For example:
    /// 
    /// ```swift
    /// func didPressSignOut() {
    ///     guard let session = Descope.sessionManager.session else { return }
    /// 
    ///     // clear the session locally from the app and spawn a background task to revoke
    ///     // the refreshJWT from the Descope servers without waiting for the call to finish
    ///     Descope.sessionManager.clearSession()
    ///     Task {
    ///         try? await Descope.auth.revokeSessions(.currentSession, refreshJwt: session.refreshJwt)
    ///     }
    /// 
    ///     showLaunchScreen()
    /// }
    /// ```
    /// 
    /// - Important: When called with `.allSessions` the provided refresh JWT will not
    ///     be usable anymore and the user will need to sign in again.
    /// 
    /// - Parameters:
    ///   - revoke: Pass `.currentSession` to revoke the session in the `refreshJwt`
    ///     parameter or see ``RevokeType`` for more options.
    ///   - refreshJwt: The `refreshJwt` from an active ``DescopeSession``.
    func revokeSessions(_ revoke: RevokeType, refreshJwt: String, completion: @escaping @Sendable (Result<Void, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await revokeSessions(revoke, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeEnchantedLink {
    /// Authenticates a new user using an enchanted link, sent via email.
    /// 
    /// The caller should use the returned ``EnchantedLinkResponse`` object to show the
    /// user which link they need to press in the enchanted link email, and then use
    /// the `pendingRef` value to poll until the authentication is verified.
    /// 
    /// - Important: Make sure an email address is provided via
    ///     the `details` parameter or as the `loginId` itself.
    /// 
    /// - Important: Make sure a default Enchanted Link URL is configured
    ///     in the Descope console, or provided by this call.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - details: Optional details about the user signing up.
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    /// 
    /// - Returns: An ``EnchantedLinkResponse`` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func signUp(loginId: String, details: SignUpDetails?, redirectURL: String?, completion: @escaping @Sendable (Result<EnchantedLinkResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUp(loginId: loginId, details: details, redirectURL: redirectURL)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user using an enchanted link, sent via email.
    /// 
    /// The caller should use the returned ``EnchantedLinkResponse`` object to show the
    /// user which link they need to press in the enchanted link email, and then use
    /// the `pendingRef` value to poll until the authentication is verified.
    /// 
    /// - Important: Make sure a default Enchanted link URL is configured
    ///     in the Descope console, or provided by this call.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - options: Additional behaviors to perform during authentication.
    /// 
    /// - Returns: An ``EnchantedLinkResponse`` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func signIn(loginId: String, redirectURL: String?, options: [SignInOptions], completion: @escaping @Sendable (Result<EnchantedLinkResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signIn(loginId: loginId, redirectURL: redirectURL, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user if one exists, or create a new user using an
    /// enchanted link, sent via email.
    /// 
    /// The caller should use the returned ``EnchantedLinkResponse`` object to show the
    /// user which link they need to press in the enchanted link email, and then use
    /// the `pendingRef` value to poll until the authentication is verified.
    /// 
    /// - Important: Make sure a default Enchanted link URL is configured
    ///     in the Descope console, or provided by this call.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - options: Additional behaviors to perform during authentication.
    /// 
    /// - Returns: An ``EnchantedLinkResponse`` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func signUpOrIn(loginId: String, redirectURL: String?, options: [SignInOptions], completion: @escaping @Sendable (Result<EnchantedLinkResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUpOrIn(loginId: loginId, redirectURL: redirectURL, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing user by adding an email address.
    /// 
    /// The email will be updated after it is verified via enchanted link. In order to
    /// do this, the user must have an active ``DescopeSession`` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    /// 
    /// The caller should use the returned ``EnchantedLinkResponse`` object to show the
    /// user which link they need to press in the enchanted link email, and then use
    /// the `pendingRef` value to poll until the authentication is verified.
    /// 
    /// - Parameters:
    ///   - email: The email address to add.
    ///   - loginId: The existing user's loginId
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - refreshJwt: The existing user's `refreshJwt` from an active ``DescopeSession``.
    ///   - options: Whether to add the new email address as a loginId for the updated user, and
    ///     in that case, if another user already has the same email address as a loginId how to
    ///     merge the two users. See the documentation for ``UpdateOptions`` for more details.
    /// 
    /// - Returns: An ``EnchantedLinkResponse`` object with the `linkId` to show the
    ///     user and `pendingRef` for polling for the session.
    func updateEmail(_ email: String, loginId: String, redirectURL: String?, refreshJwt: String, options: UpdateOptions, completion: @escaping @Sendable (Result<EnchantedLinkResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await updateEmail(email, loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Checks if an enchanted link authentication has been verified by the user.
    /// 
    /// This function will only return an ``AuthenticationResponse`` successfully after
    /// the user presses the enchanted link in the authentication email.
    /// 
    /// - Important: This function doesn't perform any polling or waiting, so calling code
    ///     should expect to catch any thrown `DescopeError.enchantedLinkPending` errors and
    ///     handle them appropriately. For most use cases it might be more convenient to
    ///     use ``pollForSession(pendingRef:timeout:)`` instead.
    /// 
    /// - Parameter pendingRef: The pendingRef value from an ``EnchantedLinkResponse`` object.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    func checkForSession(pendingRef: String, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await checkForSession(pendingRef: pendingRef)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Waits until an enchanted link authentication has been verified by the user.
    /// 
    /// This function will only return an ``AuthenticationResponse`` successfully after
    /// the user presses the enchanted link in the authentication email.
    /// 
    /// This function calls ``checkForSession(pendingRef:)`` periodically until the authentication
    /// is verified. It will keep polling even if it encounters network errors, but
    /// any other unexpected errors will be rethrown. If the timeout expires a
    /// `DescopeError.enchantedLinkExpired` error is thrown.
    /// 
    /// If the current task is cancelled, this function will stop polling and
    /// throw a `CancellationError` as expected.
    /// 
    /// - Parameters:
    ///   - pendingRef: The pendingRef value from an ``EnchantedLinkResponse`` object.
    ///   - timeout: An optional number of seconds to poll for until giving up. If not
    ///     given a default value of 2 minutes is used.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    func pollForSession(pendingRef: String, timeout: TimeInterval?, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await pollForSession(pendingRef: pendingRef, timeout: timeout)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeMagicLink {
    /// Authenticates a new user using a magic link, sent via a delivery
    /// method of choice.
    /// 
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `details` parameter or as
    ///     the `loginId` itself, i.e., the email address, phone number, etc.
    /// 
    /// - Important: Make sure a default magic link URL is configured
    ///     in the Descope console, or provided by this call.
    /// 
    /// - Parameters:
    ///   - method: Deliver the magic link using this delivery method.
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - details: Optional details about the user signing up.
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    func signUp(with method: DeliveryMethod, loginId: String, details: SignUpDetails?, redirectURL: String?, completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUp(with: method, loginId: loginId, details: details, redirectURL: redirectURL)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user using a magic link, sent via a delivery
    /// method of choice.
    /// 
    /// - Important: Make sure a default magic link URL is configured
    ///     in the Descope console, or provided by this call.
    /// 
    /// - Parameters:
    ///   - method: Deliver the magic link using this delivery method.
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - options: Additional behaviors to perform during authentication.
    func signIn(with method: DeliveryMethod, loginId: String, redirectURL: String?, options: [SignInOptions], completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signIn(with: method, loginId: loginId, redirectURL: redirectURL, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user if one exists, or creates a new user
    /// using a magic link, sent via a delivery method of choice.
    /// 
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `loginId` itself,
    ///     i.e., the email address, phone number, etc.
    /// 
    /// - Important: Make sure a default magic link URL is configured
    ///     in the Descope console, or provided by this call.
    /// 
    /// - Parameters:
    ///   - method: Deliver the magic link using this delivery method.
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - options: Additional behaviors to perform during authentication.
    func signUpOrIn(with method: DeliveryMethod, loginId: String, redirectURL: String?, options: [SignInOptions], completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUpOrIn(with: method, loginId: loginId, redirectURL: redirectURL, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing user by adding an email address.
    /// 
    /// The email will be updated after it is verified via magic link. In order to do
    /// this, the user must have an active ``DescopeSession`` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    /// 
    /// - Parameters:
    ///   - email: The email address to add.
    ///   - loginId: The existing user's loginId
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - refreshJwt: The existing user's `refreshJwt` from an active ``DescopeSession``.
    ///   - options: Whether to add the new email address as a loginId for the updated user, and
    ///     in that case, if another user already has the same email address as a loginId how to
    ///     merge the two users. See the documentation for ``UpdateOptions`` for more details.
    func updateEmail(_ email: String, loginId: String, redirectURL: String?, refreshJwt: String, options: UpdateOptions, completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await updateEmail(email, loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing user by adding a phone number.
    /// 
    /// The phone number will be updated after it is verified via magic link. In order
    /// to do this, the user must have an active ``DescopeSession`` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    /// 
    /// - Important: Make sure the delivery information corresponding with
    ///     the phone number enabled delivery method.
    /// 
    /// - Parameters:
    ///   - phone: The phone number to add.
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: The existing user's loginId
    ///   - redirectURL: Optional URL that will be used to generate the magic link.
    ///     If not given, the project default will be used.
    ///   - refreshJwt: The existing user's `refreshJwt` from an active ``DescopeSession``.
    ///   - options: Whether to add the new phone number as a loginId for the updated user, and
    ///     in that case, if another user already has the same phone number as a loginId how to
    ///     merge the two users. See the documentation for ``UpdateOptions`` for more details.
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, redirectURL: String?, refreshJwt: String, options: UpdateOptions, completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await updatePhone(phone, with: method, loginId: loginId, redirectURL: redirectURL, refreshJwt: refreshJwt, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Verifies a magic link token.
    /// 
    /// In order to effectively do this, the link generated should refer back to
    /// the app, then the `t` URL parameter should be extracted and sent to this
    /// function. An ``AuthenticationResponse`` value upon successful authentication.
    /// 
    /// - Parameter token: The extracted token from the `t` URL parameter from the magic link.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    func verify(token: String, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await verify(token: token)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeOAuth {
    /// Authenticates the user with OAuth using a sandboxed authentication view.
    /// 
    /// This API is a convenience method that calls `webStart`, presents the OAuth webpage
    /// using `ASWebAuthenticationSession`, and then finally calls `webExchange`.
    /// 
    /// - Parameters:
    ///   - provider: The provider the user wishes to authenticate with.
    ///   - accessSharedUserData: Whether the authentication view is allowed to access shared
    ///     user data. See the note below for more details.
    ///   - options: Require additional behaviors when authenticating a user.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    /// 
    /// - Throws: ``DescopeError/webAuthCancelled`` if the authentication view is aborted
    ///     or cancelled by the user.
    /// 
    /// - Note: Setting `accessSharedUserData` to `true` allows the sandboxed browser in the
    ///     authentication view to access cookies and other browsing data from the user's
    ///     regular browser in the device. Users are often logged in to their OAuth provider
    ///     in the device's regular browser, and enabling this setting should let them use
    ///     their active session when authenticating rather than forcing them to login to
    ///     the provider again. A side effect of enabling this is that the device will show
    ///     a dialog before the authentication view is presented, asking the user to allow
    ///     the app to share information with the browser.
    /// 
    /// - Important: This is an asynchronous operation that performs network requests before
    ///     and after displaying the modal authentication view. It is thus recommended to show
    ///     an activity indicator or switch the user interface to a loading state before calling
    ///     this, otherwise the user might accidentally interact with the app when the
    ///     authentication view is not being displayed.
    @MainActor
    func web(provider: OAuthProvider, accessSharedUserData: Bool, options: [SignInOptions], completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await web(provider: provider, accessSharedUserData: accessSharedUserData, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Starts an OAuth redirect chain to authenticate a user.
    /// 
    /// It's recommended to use `ASWebAuthenticationSession` to perform the authentication.
    /// 
    ///     // use one of the built in constants for the OAuth provider
    ///     let authURL = try await Descope.oauth.webStart(provider: .apple, redirectURL: nil)
    /// 
    ///     // or pass a string with the name of a custom provider
    ///     let authURL = try await Descope.oauth.webStart(provider: "myprovider", redirectURL: nil)
    /// 
    /// - Important: Make sure a default OAuth redirect URL is configured
    ///     in the Descope console, or provided by this call.
    /// 
    /// - Parameters:
    ///   - provider: The provider the user wishes to authenticate with.
    ///   - redirectURL: An optional parameter to generate the OAuth link.
    ///     If not given, the project default will be used.
    ///   - options: Require additional behaviors when authenticating a user.
    /// 
    /// - Returns: A URL to redirect to in order to authenticate the user against
    ///     the chosen provider.
    func webStart(provider: OAuthProvider, redirectURL: String?, options: [SignInOptions], completion: @escaping @Sendable (Result<URL, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await webStart(provider: provider, redirectURL: redirectURL, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Completes an OAuth redirect chain by exchanging the code received in
    /// the `code` URL parameter for an ``AuthenticationResponse``.
    /// 
    /// - Parameter code: The code appended to the returning URL via the
    ///     `code` URL parameter.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful exchange.
    func webExchange(code: String, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await webExchange(code: code)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates the user using the native `Sign in with Apple` dialog.
    /// 
    /// This API enables a more streamlined user experience than the equivalent browser
    /// based OAuth authentication, when using the `.apple` provider or a custom provider
    /// that's configured for Apple. The authentication presents a native dialog that lets
    /// the user sign in with the Apple ID they're already using on their device.
    /// 
    /// The Sign in with Apple APIs require some setup in your Xcode project, including
    /// at the very least adding the `Sign in with Apple` capability. You will also need
    /// to configure the Apple provider in the [Descope console](https://app.descope.com/settings/authentication/social).
    /// In particular, when using your own account make sure that the `Client ID` value
    /// matches the Bundle Identifier of your app.
    /// 
    /// - Parameters:
    ///   - provider: The provider the user wishes to authenticate with, this will usually
    ///     either be `.apple` or the name of a custom provider that's configured for Apple.
    ///   - options: Require additional behaviors when authenticating a user.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    /// 
    /// - Throws: ``DescopeError/oauthNativeCancelled`` if the authentication view is aborted
    ///     or cancelled by the user.
    /// 
    /// - Note: This is an asynchronous operation that performs network requests before and
    ///     after displaying the modal authentication view. It is thus recommended to show an
    ///     activity indicator or switch the user interface to a loading state before calling
    ///     this, otherwise the user might accidentally interact with the app when the
    ///     authentication view is not being displayed.
    /// 
    /// - SeeAlso: For more details about configuring your app and generating client secrets
    ///     see the [Sign in with Apple documentation](https://developer.apple.com/sign-in-with-apple/get-started/).
    @MainActor
    func native(provider: OAuthProvider, options: [SignInOptions], completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await native(provider: provider, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeOTP {
    /// Authenticates a new user using an OTP, sent via a delivery
    /// method of choice.
    /// 
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given either in the `user` parameter or as
    ///     the `loginId` itself, i.e., the email address, phone number, etc.
    /// 
    /// - Parameters:
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - details: Optional details about the user signing up.
    func signUp(with method: DeliveryMethod, loginId: String, details: SignUpDetails?, completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUp(with: method, loginId: loginId, details: details)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user using an OTP, sent via a delivery
    /// method of choice.
    /// 
    /// - Parameters:
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - options: Additional behaviors to perform during authentication.
    func signIn(with method: DeliveryMethod, loginId: String, options: [SignInOptions], completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signIn(with: method, loginId: loginId, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user if one exists, or creates a new user
    /// using an OTP, sent via a delivery method of choice.
    /// 
    /// - Important: Make sure the delivery information corresponding with
    ///     the delivery method is given in the `loginId` parameter, i.e., the
    ///     email address, phone number, etc.
    /// 
    /// - Parameters:
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier
    ///   - options: Additional behaviors to perform during authentication.
    func signUpOrIn(with method: DeliveryMethod, loginId: String, options: [SignInOptions], completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUpOrIn(with: method, loginId: loginId, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Verifies an OTP code sent to the user.
    /// 
    /// - Parameters:
    ///   - method: Which delivery method was used to send the OTP code
    ///   - loginId: The loginId value used to initiate the authentication.
    ///   - code: The code to validate.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    func verify(with method: DeliveryMethod, loginId: String, code: String, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await verify(with: method, loginId: loginId, code: code)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing user by adding an email address.
    /// 
    /// The email will be updated after it is verified via OTP. In order to do this,
    /// the user must have an active ``DescopeSession`` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    /// 
    /// - Parameters:
    ///   - email: The email address to add.
    ///   - loginId: The existing user's loginId
    ///   - refreshJwt: The existing user's `refreshJwt` from an active ``DescopeSession``.
    ///   - options: Whether to add the new email address as a loginId for the updated user, and
    ///     in that case, if another user already has the same email address as a loginId how to
    ///     merge the two users. See the documentation for ``UpdateOptions`` for more details.
    func updateEmail(_ email: String, loginId: String, refreshJwt: String, options: UpdateOptions, completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await updateEmail(email, loginId: loginId, refreshJwt: refreshJwt, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing user by adding a phone number.
    /// 
    /// The phone number will be updated after it is verified via OTP. In order to do
    /// this, the user must have an active ``DescopeSession`` whose `refreshJwt` should
    /// be passed as a parameter to this function.
    /// 
    /// - Important: Make sure delivery method is appropriate for using a phone number.
    /// 
    /// - Parameters:
    ///   - phone: The phone number to add.
    ///   - method: Deliver the OTP code using this delivery method.
    ///   - loginId: The existing user's loginId
    ///   - refreshJwt: The existing user's `refreshJwt` from an active ``DescopeSession``.
    ///   - options: Whether to add the new phone number as a loginId for the updated user, and
    ///     in that case, if another user already has the same phone number as a loginId how to
    ///     merge the two users. See the documentation for ``UpdateOptions`` for more details.
    func updatePhone(_ phone: String, with method: DeliveryMethod, loginId: String, refreshJwt: String, options: UpdateOptions, completion: @escaping @Sendable (Result<String, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await updatePhone(phone, with: method, loginId: loginId, refreshJwt: refreshJwt, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopePasskey {
    /// Authenticates a new user by creating a new passkey.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - details: Optional details about the user signing up.
    /// 
    /// - Throws: ``DescopeError/passkeyCancelled`` if the async task is cancelled or
    ///     the authentication view is cancelled by the user.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    @available(iOS 15.0, *)
    func signUp(loginId: String, details: SignUpDetails?, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUp(loginId: loginId, details: details)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user by prompting for an existing passkey.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - options: Additional behaviors to perform during authentication.
    /// 
    /// - Throws: ``DescopeError/passkeyCancelled`` if the async task is cancelled or
    ///     the authentication view is cancelled by the user.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    @available(iOS 15.0, *)
    func signIn(loginId: String, options: [SignInOptions], completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signIn(loginId: loginId, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user if one exists or creates a new one.
    /// 
    /// A new passkey will be created if the user doesn't already exist, otherwise a passkey
    /// must be available on their device to authenticate with.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - options: Additional behaviors to perform during authentication.
    /// 
    /// - Throws: ``DescopeError/passkeyCancelled`` if the async task is cancelled or
    ///     the authentication view is cancelled by the user.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    @available(iOS 15.0, *)
    func signUpOrIn(loginId: String, options: [SignInOptions], completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUpOrIn(loginId: loginId, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing user by adding a new passkey as an authentication method.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - refreshJwt: the `refreshJwt` from an active ``DescopeSession``.
    /// 
    /// - Throws: ``DescopeError/passkeyCancelled`` if the async task is cancelled or
    ///     the authentication view is cancelled by the user.
    @available(iOS 15.0, *)
    func add(loginId: String, refreshJwt: String, completion: @escaping @Sendable (Result<Void, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await add(loginId: loginId, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopePassword {
    /// Creates a new user that can later sign in with a password.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - details: Optional details about the user signing up.
    ///   - password: The user's password.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    func signUp(loginId: String, password: String, details: SignUpDetails?, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUp(loginId: loginId, password: password, details: details)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Authenticates an existing user using a password.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in,
    ///     typically an email, phone, or any other unique identifier.
    ///   - password: The user's password.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    func signIn(loginId: String, password: String, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signIn(loginId: loginId, password: password)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates a user's password.
    /// 
    /// In order to do this, the user must have an active ``DescopeSession`` whose
    /// `refreshJwt` should be passed as a parameter to this function.
    /// 
    /// The value for `newPassword` must conform to the password policy defined in the
    /// password settings in the Descope console
    /// 
    /// - Parameters:
    ///   - loginId: The existing user's loginId.
    ///   - newPassword: The new password to set for the user.
    ///   - refreshJwt: The existing user's `refreshJwt` from an active ``DescopeSession``.
    func update(loginId: String, newPassword: String, refreshJwt: String, completion: @escaping @Sendable (Result<Void, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await update(loginId: loginId, newPassword: newPassword, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Replaces a user's password by providing their current password.
    /// 
    /// The value for `newPassword` must conform to the password policy defined in the
    /// password settings in the Descope console
    /// 
    /// - Parameters:
    ///   - loginId: The existing user's loginId.
    ///   - oldPassword: The user's current password.
    ///   - newPassword: The new password to set for the user.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful replacement and authentication.
    func replace(loginId: String, oldPassword: String, newPassword: String, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await replace(loginId: loginId, oldPassword: oldPassword, newPassword: newPassword)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Sends a password reset email to the user.
    /// 
    /// This operation starts a Magic Link or Enchanted Link flow depending on the
    /// configuration in the Descope console. After the authentication flow is finished
    /// use the `refreshJwt` to call `update` and change the user's password.
    /// 
    /// - Important: The user must be verified according to the configured
    /// password reset method.
    /// 
    /// - Parameters:
    ///   - loginId: The existing user's loginId.
    ///   - redirectURL: Optional URL that is used by Magic Link or Enchanted Link
    ///     if those are the chosen reset methods.
    func sendReset(loginId: String, redirectURL: String?, completion: @escaping @Sendable (Result<Void, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await sendReset(loginId: loginId, redirectURL: redirectURL)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Fetches the rules for valid passwords.
    /// 
    /// The policy is configured in the password settings in the Descope console, and
    /// these values can be used to implement client-side validation of new user passwords
    /// for a better user experience.
    /// 
    /// In any case, all password rules are enforced by Descope on the server side as well.
    func getPolicy(completion: @escaping @Sendable (Result<PasswordPolicyResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await getPolicy()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeSSO {
    /// Starts an SSO redirect chain to authenticate a user.
    /// 
    /// It's recommended to use `ASWebAuthenticationSession` to perform the authentication.
    /// 
    /// - Important: Make sure a default SSO redirect URL is configured
    ///     in the Descope console, or provided by this call.
    /// 
    /// - Parameters:
    ///   - emailOrTenantName: The user's email address or tenant name.
    ///   - redirectURL: An optional parameter to generate the SSO link.
    ///     If not given, the project default will be used.
    ///   - options: Require additional behaviors when authenticating a user.
    /// 
    /// - Returns: A URL to redirect to in order to authenticate the user against
    ///     the chosen provider.
    func start(emailOrTenantName: String, redirectURL: String?, options: [SignInOptions], completion: @escaping @Sendable (Result<URL, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await start(emailOrTenantName: emailOrTenantName, redirectURL: redirectURL, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Completes an SSO redirect chain by exchanging the code received in
    /// the `code` URL parameter for an ``AuthenticationResponse``.
    /// 
    /// - Parameter code: The code appended to the returning URL via the
    ///     `code` URL parameter.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful exchange.
    func exchange(code: String, completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await exchange(code: code)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}

public extension DescopeTOTP {
    /// Authenticates a new user using a TOTP. This function returns the
    /// key (seed) that allows authenticator apps to generate TOTP codes.
    /// 
    /// - Parameters:
    ///   - loginId: What identifies the user when logging in, typically
    ///     an email, phone, or any other unique identifier.
    ///   - details: Optional details about the user signing up.
    /// 
    /// - Returns: A ``TOTPResponse`` object with the key (seed) in multiple formats.
    func signUp(loginId: String, details: SignUpDetails?, completion: @escaping @Sendable (Result<TOTPResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await signUp(loginId: loginId, details: details)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Updates an existing user by adding TOTP as an authentication method.
    /// 
    /// In order to do this, the user must have an active ``DescopeSession`` whose
    /// `refreshJwt` should be passed as a parameter to this function.
    /// 
    /// The function returns the key (seed) that allows authenticator
    /// apps to generate TOTP codes.
    /// 
    /// - Parameters:
    ///   - loginId: The existing user's loginId
    ///   - refreshJwt: The existing user's `refreshJwt` from an active ``DescopeSession``.
    /// 
    /// - Returns: A ``TOTPResponse`` object with the key (seed) in multiple formats.
    func update(loginId: String, refreshJwt: String, completion: @escaping @Sendable (Result<TOTPResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await update(loginId: loginId, refreshJwt: refreshJwt)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    /// Verifies a TOTP code that was generated by an authenticator app.
    /// 
    /// - Parameters:
    ///   - loginId: The `loginId` of the user trying to log in.
    ///   - code: The code to validate.
    ///   - options: Additional behaviors to perform during authentication.
    /// 
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    func verify(loginId: String, code: String, options: [SignInOptions], completion: @escaping @Sendable (Result<AuthenticationResponse, DescopeError>) -> Void) {
        Task {
            do throws(DescopeError) {
                completion(.success(try await verify(loginId: loginId, code: code, options: options)))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
