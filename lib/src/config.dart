
/// The default base URL for the Descope API.
const defaultBaseUrl = 'https://api.descope.com';

/// The configuration of the Descope SDK.
class DescopeConfig {
  /// The id of the Descope project.
  final String projectId;

  /// The base URL of the Descope server.
  final String baseUrl;

  /// Creates a new `DescopeConfig` object.
  const DescopeConfig(this.projectId, this.baseUrl);
}
