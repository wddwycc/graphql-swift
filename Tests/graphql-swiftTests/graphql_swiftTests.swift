import XCTest
@testable import graphql_swift

final class graphql_swiftTests: XCTestCase {
    func testParser() async throws {
        let parser = try await GraphQLParser()
        let res = try await parser.parse(source: """
        directive @requiredCapabilities(
          requiredCapabilities: [String!]
        ) on ARGUMENT_DEFINITION | ENUM | ENUM_VALUE | FIELD_DEFINITION | INPUT_FIELD_DEFINITION | INPUT_OBJECT | INTERFACE | OBJECT | SCALAR | UNION
        """)
        debugPrint(res)
    }
}
