
final class Push: DescopePush {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func enroll(token: String, development: Bool, refreshJwt: String) async throws(DescopeError) {
        let provider = development ? "apndev" : "apn"
        try await client.pushEnrollDevice(provider: provider, token: token, device: SystemInfo.device, refreshJwt: refreshJwt)
    }
    
    func finish(transactionId: String, approved: Bool, refreshJwt: String) async throws(DescopeError) {
        try await client.pushSignInFinish(transactionId: transactionId, approved: approved, refreshJwt: refreshJwt)
    }
}
