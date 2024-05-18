import XCTest
@testable import GraphQLCodeGen

class UtilsTests: XCTestCase {
    func testSubString() {
        XCTAssertEqual("abc".subString(from: 0, to: 2), "ab")
    }
    
    func testFirstLetterLowercased() {
        XCTAssertEqual("ExampleQuery".firstLetterLowercased(), "exampleQuery")
        XCTAssertEqual("".firstLetterLowercased(), "")
    }
}
