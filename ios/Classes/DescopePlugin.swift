import AuthenticationServices
import Flutter

private let redirectScheme = "descopeauth"
private let redirectURL = "\(redirectScheme)://flow"

public class DescopePlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    private let defaultContextProvider = DefaultContextProvider()
    private var eventSink: FlutterEventSink?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "descope_flutter/methods", binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "descope_flutter/events", binaryMessenger: registrar.messenger())
        
        let instance = DescopePlugin()
        
        eventChannel.setStreamHandler(instance as FlutterStreamHandler & NSObjectProtocol)
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "start":
            if let args = call.arguments as? Dictionary<String, Any>,
               let urlString = args["url"] as? String {
                startFlow(urlString)
                result(urlString)
            } else {
                result(FlutterError.init(code: "MISSINGURL", message: nil, details: nil))
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // FlutterStreamHandler
    
    public func onListen(withArguments arguments: Any?, eventSink: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = eventSink
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        return nil
    }
    
    // Internal
    
    private func startFlow(_ urlString: String) {
        Task { @MainActor in
            guard var url = URL(string: urlString) else { return }
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: redirectScheme) { callbackURL, error in
                if let error {
                    switch error {
                    case ASWebAuthenticationSessionError.canceledLogin:
                        self.eventSink?("canceled")
                        return
                    // case ASWebAuthenticationSessionError.presentationContextInvalid:
                    // case ASWebAuthenticationSessionError.presentationContextNotProvided:
                    default:
                        self.eventSink?("")
                        return
                    }
                }
                self.eventSink?(callbackURL?.absoluteString ?? "")
            }
            session.prefersEphemeralWebBrowserSession = true
            session.presentationContextProvider = defaultContextProvider
            session.start()
        }
    }
}


private class DefaultContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
#if os(macOS)
        return ASPresentationAnchor()
#else
        let scene = UIApplication.shared.connectedScenes
            .filter { $0.activationState == .foregroundActive }
            .compactMap { $0 as? UIWindowScene }
            .first
        
        let keyWindow = scene?.windows
            .first { $0.isKeyWindow }
        
        return keyWindow ?? ASPresentationAnchor()
#endif
    }
}
