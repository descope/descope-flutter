
final class AccessKey: DescopeAccessKey {
    let client: DescopeClient
    
    init(client: DescopeClient) {
        self.client = client
    }
    
    func exchange(accessKey: String) async throws -> DescopeToken {
        return try await client.accessKeyExchange(accessKey).convert()
    }
}

private extension DescopeClient.AccessKeyExchangeResponse {
    func convert() throws -> DescopeToken {
        return try Token(jwt: sessionJwt)
    }
}
