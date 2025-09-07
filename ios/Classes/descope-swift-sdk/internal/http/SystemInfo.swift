import Foundation

enum SystemInfo {
    static let osName = makeOSName()
    static let osVersion = makeOSVersion()
    static let appName = makeAppName()
    static let appVersion = makeAppVersion()
    static let device = makeDevice()
}

private func makeOSName() -> String {
    #if os(iOS)
    return "ios"
    #else
    return "macos"
    #endif
}

private func makeOSVersion() -> String {
    let ver = ProcessInfo.processInfo.operatingSystemVersion
    return "\(ver.majorVersion).\(ver.minorVersion).\(ver.patchVersion)"
}

private func makeAppName() -> String? {
    return Bundle.main.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
}

private func makeAppVersion() -> String? {
    guard let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String, !version.isEmpty else { return nil }
    guard let build = Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String, !build.isEmpty else { return version }
    return "\(version).\(build)"
}

private func makeDevice() -> String? {
    #if targetEnvironment(simulator)
    return "Simulator"
    #else
    // use different ioctl name according to os
    #if os(iOS)
    let ioctl = "hw.machine"
    #else
    let ioctl = "hw.model"
    #endif

    // get the size of the value first
    var size = 0
    guard sysctlbyname(ioctl, nil, &size, nil, 0) == 0, size > 0 else { return nil }

    // create an appropriately sized array and call again to retrieve the value
    var chars = [CChar](repeating: 0, count: size)
    guard sysctlbyname(ioctl, &chars, &size, nil, 0) == 0 else { return nil }

    // the device model, e.g., "MacBookPro18,4" or "iPhone17,2"
    return String(utf8String: chars)
    #endif
}
