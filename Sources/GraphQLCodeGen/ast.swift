import GraphQLParser

/**
 walk through ASTNode using a depth-first traversal
 */
func visit(node: ASTNode, onEnter: (ASTNode) -> Void) {
    onEnter(node)
    for child in node.children {
        visit(node: child, onEnter: onEnter)
    }
}
