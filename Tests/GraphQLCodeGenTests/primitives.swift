import XCTest
@testable import GraphQLCodeGen

class PrimitivesTests: XCTestCase {
    func testSafeFieldName() {
        XCTAssertEqual(safeFieldName("enum"), "`enum`")
    }
    
    func testGenerateCodeComment() {
        XCTAssertEqual(
            generateCodeComment(description: "A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.\n\nIn some cases, you need to provide options to alter GraphQL's execution behavior in ways field arguments will not suffice, such as conditionally including or skipping a field. Directives provide this by describing additional information to the executor.").description
            ,
            """
            /**
            A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.
            
            In some cases, you need to provide options to alter GraphQL's execution behavior in ways field arguments will not suffice, such as conditionally including or skipping a field. Directives provide this by describing additional information to the executor.
            */
            
            """
        )
        
    }
}

/// A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.
///
/// In some cases, you need to provide options to alter GraphQL's execution behavior in ways field arguments will not suffice, such as conditionally including or skipping a field. Directives provide this by describing additional information to the executor.

/// A Directive provides a way to describe alternate runtime execution and type validation behavior in a GraphQL document.
///
/// In some cases, you need to provide options to alter GraphQL's execution behavior in ways field arguments will not suffice, such as conditionally including or skipping a field. Directives provide this by describing additional information to the executor.
