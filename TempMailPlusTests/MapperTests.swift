import XCTest
@testable import TempMailPlus

final class MapperTests: XCTestCase {

    func test_emailDto_toDomain_mapsFields() throws {
        let json = """
        {
          "id": "e1",
          "from": "a@b.com",
          "fromName": "Sender",
          "subject": "Hi",
          "date": "2023-11-14T22:13:20Z",
          "content": "<p>body</p>",
          "read": true,
          "attachments": [
            { "filename": "f.pdf", "contentType": "application/pdf", "size": 2048, "url": "https://x/f.pdf" }
          ]
        }
        """.data(using: .utf8)!

        let dto = try JSONDecoder().decode(EmailDto.self, from: json)
        let email = dto.toDomain()

        XCTAssertEqual(email.id, "e1")
        XCTAssertEqual(email.from, "a@b.com")
        XCTAssertEqual(email.fromName, "Sender")
        XCTAssertEqual(email.subject, "Hi")
        XCTAssertEqual(email.body, "<p>body</p>")
        XCTAssertTrue(email.isRead)
        XCTAssertEqual(email.receivedAt, 1_700_000_000_000)
        XCTAssertEqual(email.attachments.count, 1)
        XCTAssertEqual(email.attachments.first?.fileName, "f.pdf")
        XCTAssertEqual(email.attachments.first?.size, 2048)
    }

    func test_emailDto_toleratesMissingFields() throws {
        let dto = try JSONDecoder().decode(EmailDto.self, from: "{}".data(using: .utf8)!)
        let email = dto.toDomain()
        XCTAssertEqual(email.id, "")
        XCTAssertEqual(email.attachments.count, 0)
        // Missing `date` → receivedAt is 0 (Android: `date?.let { ... } ?: 0`).
        XCTAssertEqual(email.receivedAt, 0)
    }

    func test_emailDto_invalidDate_fallsBackToNow() throws {
        // Present-but-unparseable date → fallback to ~now (non-zero).
        let json = #"{"id":"e2","date":"not-a-date"}"#.data(using: .utf8)!
        let email = try JSONDecoder().decode(EmailDto.self, from: json).toDomain()
        XCTAssertGreaterThan(email.receivedAt, 0)
    }

    func test_customEmailResponse_defaultsExpiresAt() throws {
        let dto = try JSONDecoder().decode(CustomEmailResponse.self, from: #"{"code":"SUCCESS"}"#.data(using: .utf8)!)
        XCTAssertEqual(dto.code, "SUCCESS")
        XCTAssertEqual(dto.expiresAt, 0)
        XCTAssertNil(dto.email)
    }
}
