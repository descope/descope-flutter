import UIKit
import Flutter

public class FlutterDescopeFlowViewFactory: NSObject, FlutterPlatformViewFactory {
    private let messenger: FlutterBinaryMessenger

    public init(messenger: FlutterBinaryMessenger) {
        self.messenger = messenger
        super.init()
    }

    public func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        return FlutterDescopeFlowView(frame: frame, viewIdentifier: viewId, arguments: args, binaryMessenger: messenger)
    }

    public func createArgsCodec() -> (FlutterMessageCodec & NSObjectProtocol) {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

final class FlutterDescopeFlowView: NSObject, FlutterPlatformView {
    private var flowView: DescopeFlowViewWrapper
    private let channel: FlutterMethodChannel

    init(frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?, binaryMessenger messenger: FlutterBinaryMessenger) {
        let channelName = "com.descope.flow/view_\(viewId)"
        channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)

        flowView = DescopeFlowViewWrapper()
        flowView.channel = channel
        super.init()

        let config = args as? [String: Any] ?? [:]
        flowView.start(config)
    }

    func view() -> UIView {
        flowView
    }
}

class DescopeFlowViewWrapper: DescopeFlowView, DescopeFlowViewDelegate {
    var channel: FlutterMethodChannel? {
      didSet {
        channel?.setMethodCallHandler(handleMethodCall)
      }
    }

    func start(_ config: [String : Any]) {
        delegate = self
        guard let url = config["url"] as? String else { return }
        let descopeFlow = DescopeFlow(url: url)
        if let oauthNativeProvider = config["iosOAuthNativeProvider"] as? String {
            descopeFlow.oauthNativeProvider = OAuthProvider(stringLiteral: oauthNativeProvider)
        }
        if let magicLinkRedirect = config["magicLinkRedirect"] as? String {
            descopeFlow.magicLinkRedirect = magicLinkRedirect
        }

        start(flow: descopeFlow)
    }

    // Method call handler for incoming calls from Dart
    private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "resumeFromDeepLink":
            resumeFromDeepLink(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func resumeFromDeepLink(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any], let urlString = args["url"] as? String, let url = URL(string: urlString) else { return result(FlutterError(code: "MISSINGARGS", message: "'url' is required for resumeFromDeepLink", details: nil)) }
        Descope.handleURL(url)
        result(urlString)
    }

    // DescopeFlowViewDelegate

    func flowViewDidUpdateState(_ flowView: DescopeFlowView, to state: DescopeFlowState, from previous: DescopeFlowState) {
        // currently not implemented
    }

    func flowViewDidBecomeReady(_ flowView: DescopeFlowView) {
        self.channel?.invokeMethod("onReady", arguments: nil)
    }

    func flowViewDidInterceptNavigation(_ flowView: DescopeFlowView, url: URL, external: Bool) {
        // currently not implemented
    }

    func flowViewDidFail(_ flowView: DescopeFlowView, error: DescopeError) {
        var errorInfo: [String: Any] = [
            "code": error.code,
            "desc": error.desc,
        ]
        if let message = error.message {
            errorInfo["message"] = message
        }
        self.channel?.invokeMethod("onError", arguments: errorInfo)
    }

    func flowViewDidFinish(_ flowView: DescopeFlowView, response: AuthenticationResponse) {
        guard let encodedObject = try? JSONEncoder().encode(response), let encoded = String(bytes: encodedObject, encoding: .utf8) else { return }
        guard var dict = try? JSONSerialization.jsonObject(with: encodedObject) as? [String: Any] else { return }

        // Adjustments to match expected Flutter format
        dict.replaceKey(oldKey: "isFirstAuthentication", newKey: "firstSeen")
        guard var user = dict["user"] as? [String: Any] else { return }
        user.replaceKey(oldKey: "createdAt", newKey: "createdTime")
        user.replaceKey(oldKey: "isVerifiedEmail", newKey: "verifiedEmail")
        user.replaceKey(oldKey: "isVerifiedPhone", newKey: "verifiedPhone")
        let authentication = user["authentication"] as? [String: Any] ?? [:]
        let authorization = user["authorization"] as? [String: Any] ?? [:]
        user["password"] = authentication["password"] as? Bool ?? false
        user["roleNames"] = authorization["roles"] as? [String] ?? []
        user["ssoAppIds"] = authorization["ssoAppIds"] as? [String] ?? []
        if let value = authentication["oauth"] as? [String] {
            user["OAuth"] = value.reduce(into: [:]) { result, element in
                result[element] = true
            }
        } else {
            user["OAuth"] = [:]
        }

        // custom attributes are serialized as a JSON string
        if let value = user["customAttributes"] as? String, let json = try? JSONSerialization.jsonObject(with: Data(value.utf8)) {
            user["customAttributes"] = json as? [String: Any] ?? [:]
        } else {
            user["customAttributes"] = [:]
        }

        dict["user"] = user
        self.channel?.invokeMethod("onSuccess", arguments: dict)
    }

}

private extension [String: Any] {
    mutating func replaceKey(oldKey: String, newKey: String) {
        if let value = removeValue(forKey: oldKey) {
            self[newKey] = value
        }
    }
}
