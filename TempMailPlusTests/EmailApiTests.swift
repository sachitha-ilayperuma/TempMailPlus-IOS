import XCTest
@testable import TempMailPlus

/// Captures outgoing requests so we can assert URL/method/body construction without
/// hitting the network. (Phase 1 review carry-in #2.)
private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var responseBody: Data = Data("{}".utf8)
    nonisolated(unsafe) static var statusCode = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        Self.lastRequest = request
        let response = HTTPURLResponse(
            url: request.url!, statusCode: Self.statusCode, httpVersion: nil, headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.responseBody)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class EmailApiTests: XCTestCase {
    private func makeApi() -> EmailApiService {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: config)
        return EmailApiService(baseURL: URL(string: "https://api.example.com/")!, session: session)
    }

    override func setUp() {
        super.setUp()
        StubURLProtocol.lastRequest = nil
        StubURLProtocol.statusCode = 200
        StubURLProtocol.responseBody = Data("{}".utf8)
    }

    func test_getEmailsByAddress_buildsPathAndQuery() async throws {
        StubURLProtocol.responseBody = Data(#"{"emails":[]}"#.utf8)
        _ = try await makeApi().getEmailsByAddress(email: "abc@x.com")

        let req = try XCTUnwrap(StubURLProtocol.lastRequest)
        XCTAssertEqual(req.httpMethod, "GET")
        let comps = URLComponents(url: req.url!, resolvingAgainstBaseURL: false)!
        XCTAssertEqual(comps.path, "/get-emails-by-address")
        XCTAssertEqual(comps.queryItems?.first(where: { $0.name == "email" })?.value, "abc@x.com")
    }

    func test_createCustomEmail_isPostWithMultiSegmentPath() async throws {
        StubURLProtocol.responseBody = Data(#"{"code":"SUCCESS"}"#.utf8)
        _ = try await makeApi().createCustomEmail(
            CustomEmailRequest(prefix: "john", domain: "x.com", deviceId: "d1")
        )
        let req = try XCTUnwrap(StubURLProtocol.lastRequest)
        XCTAssertEqual(req.httpMethod, "POST")
        XCTAssertEqual(URL(string: req.url!.absoluteString)!.path, "/custom-email/create")
    }

    func test_nonSuccessStatus_throwsAPIError() async {
        StubURLProtocol.statusCode = 409
        do {
            _ = try await makeApi().createCustomEmail(
                CustomEmailRequest(prefix: "p", domain: "d", deviceId: "id")
            )
            XCTFail("Expected APIError")
        } catch let error as APIError {
            XCTAssertEqual(error.statusCode, 409)
        } catch {
            XCTFail("Expected APIError, got \(error)")
        }
    }
}
