import SwiftSyntax
import GraphQLParser

func generateResponseModelForOperationDefinitionNode(ctx: Context, operation: OperationDefinitionNode) throws -> StructDeclSyntax {
    let structName = operation.name!.value + "Response"
    let queryType = try getQueryType(schema: ctx.schema)
    return StructDeclSyntax(
        modifiers: [DeclModifierSyntax(name: .keyword(.public))],
        name: TokenSyntax.identifier(structName),
        inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: [
            .init(type: IdentifierTypeSyntax(name: TokenSyntax.identifier("Codable"))),
        ]),
        memberBlock: MemberBlockSyntax(members: try generateStructBody(ctx: ctx, selectionSet: operation.selectionSet, schemaType: queryType))
    )
}

func generateRequestForOperationDefinitionNode() {
    // TODO
}


func generateModelsForOperation(ctx: Context, operation: OperationDefinitionNode) throws -> [StructDeclSyntax] {
    return [
        try generateResponseModelForOperationDefinitionNode(ctx: ctx, operation: operation)
    ]
}
