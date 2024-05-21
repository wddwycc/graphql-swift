import XCTest
@testable import GraphQLCodeGen

class IntrospectionTests: XCTestCase {
    func testSendIntrospectionRequest() async throws {
        let _ = try await sendIntrospectionRequest(url: "https://countries.trevorblades.com")
    }
}
