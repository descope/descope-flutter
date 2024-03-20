/// Options to control how a flow runs
///
/// Platform specific options must be provided in order for a flow
/// to run correctly.
///
/// When targeting iOS and Android, provide the [DescopeMobileFlowOptions].
/// When targeting the web, provide the [DescopeWebFlowOptions].
class DescopeFlowOptions {
  DescopeMobileFlowOptions? mobile;
  DescopeWebFlowOptions? web;

  DescopeFlowOptions({this.mobile, this.web});
}

/// Options to run a mobile flow
///
/// Provide a [flowUrl] where the flow is hosted. When targeting
/// Android, or when the flow contains a magic link, make sure
/// to provide a [deepLinkUrl] to `resume` or complete the flow
/// using the `exchange` function.
class DescopeMobileFlowOptions {
  String flowUrl;
  String? deepLinkUrl;

  DescopeMobileFlowOptions({required this.flowUrl, this.deepLinkUrl});
}

/// Options to run a web flow
///
/// Provide a [flowId] to embed a flow web component
/// inside your web app. It's recommended to provide the [flowContainerCss]
/// to control how the flow is positioned and displayed.
class DescopeWebFlowOptions {
  String flowId;
  Map<String, String>? flowContainerCss;

  DescopeWebFlowOptions({required this.flowId, this.flowContainerCss});
}
