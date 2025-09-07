
public extension Descope {
    /// Provides functions for authentication using flows.
    static var flow: _DescopeFlow { sdk.flow }
}

public extension DescopeSDK {
    /// Provides functions for authentication using flows.
    var flow: _DescopeFlow { _Flow(client: client) }
}

/// Authenticate a user using a flow.
///
/// Descope Flows is a visual no-code interface to build screens and authentication flows
/// for common user interactions with your application. Flows are hosted on a webpage and
/// are run using a sandboxed browser view.
///
/// See the documentation for ``DescopeFlowRunner`` for more details.
public protocol _DescopeFlow: Sendable {
    /// Returns the ``DescopeFlowRunner`` for the current running flow or `nil` if
    /// no flow is currently running.
    @MainActor
    var current: DescopeFlowRunner? { get }

    /// Starts a user authentication flow.
    ///
    /// The flow screens are presented in a sandboxed browser view that's displayed by this
    /// method call. The method then waits until the authentication completed successfully,
    /// at which point it will return an ``AuthenticationResponse`` value as in all other
    /// authentication methods. See the documentation for ``DescopeFlowRunner`` for more
    /// details.
    ///
    /// - Note: If the `Task` that calls this method is cancelled the flow will also be
    ///     cancelled and the authentication view will be dismissed, behaving as if the
    ///     ``DescopeFlowRunner/cancel()`` method was called on the runner. See the
    ///     documentation for that method for more details.
    ///
    /// - Parameter runner: A ``DescopeFlowRunner`` that encapsulates this flow run.
    ///
    /// - Throws: ``DescopeError/flowCancelled`` if the ``DescopeFlowRunner/cancel()`` method
    ///     is called on the runner or the authentication view is cancelled by the user.
    ///
    /// - Returns: An ``AuthenticationResponse`` value upon successful authentication.
    @MainActor
    @available(*, deprecated, message: "Use DescopeFlowViewController to show a DescopeFlow instead")
    func start(runner: DescopeFlowRunner) async throws -> AuthenticationResponse
}
