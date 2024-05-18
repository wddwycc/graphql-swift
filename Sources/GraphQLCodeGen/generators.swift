import SwiftSyntax
import GraphQLParser

func convertTypeNodeToSwiftType(ctx: Context, typeNode: TypeNode, nonNull: Bool = false) throws -> TypeSyntaxProtocol {
    switch typeNode {
    case .list(let node):
        let tp = try ArrayTypeSyntax(element: convertTypeNodeToSwiftType(ctx: ctx, typeNode: node.type))
        if (nonNull) {
            return tp
        }
        return OptionalTypeSyntax(wrappedType: tp)
    case .named(let node):
        guard let schemaType = ctx.schema.types.first(where: { $0.name == node.name.value }) else {
            throw CodegenErrors.invalidType(node.name.value)
        }
        return try convertSchemaTypeToSwiftType(ctx: ctx, type: schemaType, nonNull: nonNull)
    case .nonNull(let node):
        return try convertTypeNodeToSwiftType(ctx: ctx, typeNode: node.type, nonNull: true)
    }
}

func generateRequestModelForOperationDefinitionNode(ctx: Context, operation: OperationDefinitionNode) throws -> StructDeclSyntax? {
    let structName = operation.name!.value + "Request"
    guard let variableDefinitions = operation.variableDefinitions, variableDefinitions.count > 0 else { return nil }
    let fields = try variableDefinitions.map { variableDefinition in
        let name = variableDefinition.variable.name.value
        let swiftType = try convertTypeNodeToSwiftType(ctx: ctx, typeNode: variableDefinition.type)
        return MemberBlockItemSyntax(
            // NOTE: use var here to derive more flexibile initializer for the struct
            decl: DeclSyntax("public var \(raw: name): \(swiftType)")
        )
    }
    return StructDeclSyntax(
        modifiers: [DeclModifierSyntax(name: .keyword(.public))],
        name: TokenSyntax.identifier(structName),
        inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: [
            .init(type: IdentifierTypeSyntax(name: TokenSyntax.identifier("Codable"))),
        ]),
        memberBlock: MemberBlockSyntax(members: MemberBlockItemListSyntax(fields))
    )
}

func generateResponseModelForOperationDefinitionNode(ctx: Context, operation: OperationDefinitionNode) throws -> StructDeclSyntax {
    let structName = operation.name!.value + "Response"
    let queryType = try getQueryType(schema: ctx.schema)
    return StructDeclSyntax(
        modifiers: [DeclModifierSyntax(name: .keyword(.public))],
        name: TokenSyntax.identifier(structName),
        inheritanceClause: InheritanceClauseSyntax.init(inheritedTypes: [
            .init(type: IdentifierTypeSyntax(name: TokenSyntax.identifier("Codable"))),
        ]),
        memberBlock: MemberBlockSyntax(members: try generateStructBody(ctx: ctx, schemaType: queryType, selectionSet: operation.selectionSet))
    )
}

func generateModelsForOperation(ctx: Context, operation: OperationDefinitionNode) throws -> [StructDeclSyntax] {
    var rv: [StructDeclSyntax] = []
    if let requestModel = try generateRequestModelForOperationDefinitionNode(ctx: ctx, operation: operation) {
        rv.append(requestModel)
    }
    rv.append(try generateResponseModelForOperationDefinitionNode(ctx: ctx, operation: operation))
    return rv
}

func generateClientFuncForOperationDefinitionNode(ctx: Context, operation: OperationDefinitionNode) throws -> DeclSyntax {
    let operationNameToken = TokenSyntax.identifier(lowercaseFirstLetter(operation.name!.value))
    let requestPayloadToken = TokenSyntax.identifier(operation.name!.value + "Request")
    let responsePayloadToken = TokenSyntax.identifier(operation.name!.value + "Response")
    
    if let variableDefinitions = operation.variableDefinitions, variableDefinitions.count > 0 {
        return
            """
            public func \(operationNameToken)(variables: \(requestPayloadToken)) async throws -> \(responsePayloadToken) {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let query = \(StringLiteralExprSyntax(content: try extractNodeString(ctx: ctx, node: operation)))
                let requestPayload = GraphQLRequestPayload<\(requestPayloadToken)>(query: query, variables: variables)
                request.httpBody = try JSONEncoder().encode(requestPayload)

                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return try jsonDecoder.decode(GraphQLResponsePayload<\(responsePayloadToken)>.self, from: data).data
            }
            """
    } else {
        return
            """
            public func \(operationNameToken)() async throws -> \(responsePayloadToken) {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.addValue("application/json", forHTTPHeaderField: "Content-Type")
                let query = \(StringLiteralExprSyntax(content: try extractNodeString(ctx: ctx, node: operation)))
                let requestPayload = GraphQLRequestSimplePayload(query: query)
                request.httpBody = try JSONEncoder().encode(requestPayload)

                let (data, response) = try await session.data(for: request)
                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                return try jsonDecoder.decode(GraphQLResponsePayload<\(responsePayloadToken)>.self, from: data).data
            }
            """
    }
}

