//
//  https://github.com/graphql/graphql-js/blob/v16.8.1/src/language/ast.ts
//
//
//  Created by Wen Duan on 2024/04/27.
//

import Foundation

public protocol ASTNode {
    var kind: Kind { get }
    var loc: Location? { get }
}

// MARK: Name

public class NameNode: ASTNode, Decodable {
    public var kind: Kind { .NAME }
    public let loc: Location?
    public let value: String

    public init(loc: Location?, value: String) {
        self.loc = loc
        self.value = value
    }
}

// MARK: Document

public class DocumentNode: ASTNode, Decodable {
    public var kind: Kind { .DOCUMENT }
    public let loc: Location?
    public let definitions: [DefinitionNode]

    public init(loc: Location?, definitions: [DefinitionNode]) {
        self.loc = loc
        self.definitions = definitions
    }
}

public enum DefinitionNode: Decodable {
    case executable(ExecutableDefinitionNode)
    case typeSystem(TypeSystemDefinitionNode)
    case typeSystemExtension(TypeSystemExtensionNode)

    private enum CodingKeys: String, CodingKey {
        case kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case 
            .OPERATION_DEFINITION,
            .FRAGMENT_DEFINITION:
            self = .executable(try ExecutableDefinitionNode(from: decoder))
        case 
            .SCHEMA_DEFINITION,
            .SCALAR_TYPE_DEFINITION,
            .OBJECT_TYPE_DEFINITION,
            .INTERFACE_TYPE_DEFINITION,
            .UNION_TYPE_DEFINITION,
            .ENUM_TYPE_DEFINITION,
            .INPUT_OBJECT_TYPE_DEFINITION,
            .DIRECTIVE_DEFINITION:
            self = .typeSystem(try TypeSystemDefinitionNode(from: decoder))
        case 
            .SCHEMA_EXTENSION,
            .SCALAR_TYPE_EXTENSION,
            .OBJECT_TYPE_EXTENSION,
            .INTERFACE_TYPE_EXTENSION,
            .UNION_TYPE_EXTENSION,
            .ENUM_TYPE_EXTENSION,
            .INPUT_OBJECT_TYPE_EXTENSION:
            self = .typeSystemExtension(try TypeSystemExtensionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown DefinitionNode kind")
        }
    }
}

public enum ExecutableDefinitionNode: Decodable {
    case operation(OperationDefinitionNode)
    case fragment(FragmentDefinitionNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .OPERATION_DEFINITION:
            self = .operation(try OperationDefinitionNode(from: decoder))
        case .FRAGMENT_DEFINITION:
            self = .fragment(try FragmentDefinitionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown ExecutableDefinitionNode kind")
        }
    }
}

public class OperationDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .OPERATION_DEFINITION }
    public let loc: Location?
    public let operation: OperationTypeNode
    public let name: NameNode?
    public let variableDefinitions: [VariableDefinitionNode]?
    public let directives: [DirectiveNode]?
    public let selectionSet: SelectionSetNode

    public init(loc: Location?,
                operation: OperationTypeNode,
                name: NameNode?,
                variableDefinitions: [VariableDefinitionNode]?,
                directives: [DirectiveNode]?,
                selectionSet: SelectionSetNode) {
        self.loc = loc
        self.operation = operation
        self.name = name
        self.variableDefinitions = variableDefinitions
        self.directives = directives
        self.selectionSet = selectionSet
    }
}

public enum OperationTypeNode: String, Decodable {
    case query, mutation, subscription
}

public class VariableDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .VARIABLE_DEFINITION }
    public let loc: Location?
    public let variable: VariableNode
    public let type: TypeNode
    public let defaultValue: ConstValueNode?
    public let directives: [ConstDirectiveNode]?

    public init(loc: Location?,
                variable: VariableNode,
                type: TypeNode,
                defaultValue: ConstValueNode?,
                directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.variable = variable
        self.type = type
        self.defaultValue = defaultValue
        self.directives = directives
    }
}

public class VariableNode: ASTNode, Decodable {
    public var kind: Kind { .VARIABLE }
    public let loc: Location?
    public let name: NameNode

    public init(loc: Location?,
                name: NameNode) {
        self.loc = loc
        self.name = name
    }
}

public class SelectionSetNode: ASTNode, Decodable {
    public var kind: Kind { .SELECTION_SET }
    public let loc: Location?
    public let selections: [SelectionNode]

    public init(loc: Location?,
                selections: [SelectionNode]) {
        self.loc = loc
        self.selections = selections
    }
}

public enum SelectionNode: Decodable {
    case field(FieldNode)
    case fragmentSpread(FragmentSpreadNode)
    case inlineFragment(InlineFragmentNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .FIELD:
            self = .field(try FieldNode(from: decoder))
        case .FRAGMENT_SPREAD:
            self = .fragmentSpread(try FragmentSpreadNode(from: decoder))
        case .INLINE_FRAGMENT:
            self = .inlineFragment(try InlineFragmentNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown SelectionNode kind")
        }
    }
}

public class FieldNode: ASTNode, Decodable {
    public var kind: Kind { .FIELD }
    public let loc: Location?
    public let alias: NameNode?
    public let name: NameNode
    public let arguments: [ArgumentNode]?
    public let directives: [DirectiveNode]?
    public let selectionSet: SelectionSetNode?
    
    public init(loc: Location?, alias: NameNode?, name: NameNode, arguments: [ArgumentNode]?, directives: [DirectiveNode]?, selectionSet: SelectionSetNode?) {
        self.loc = loc
        self.alias = alias
        self.name = name
        self.arguments = arguments
        self.directives = directives
        self.selectionSet = selectionSet
    }
}

public class ArgumentNode: ASTNode, Decodable {
    public var kind: Kind { .ARGUMENT }
    public let loc: Location?
    public let name: NameNode
    public let value: ValueNode
    
    public init(loc: Location?, name: NameNode, value: ValueNode) {
        self.loc = loc
        self.name = name
        self.value = value
    }
}

public class ConstArgumentNode: ASTNode, Decodable {
    public var kind: Kind { .ARGUMENT }
    public let loc: Location?
    public let name: NameNode
    public let value: ConstValueNode
    
    public init(loc: Location?, name: NameNode, value: ConstValueNode) {
        self.loc = loc
        self.name = name
        self.value = value
    }
}

// MARK: Fragments

public class FragmentSpreadNode: ASTNode, Decodable {
    public var kind: Kind { .FRAGMENT_SPREAD }
    public let loc: Location?
    public let name: NameNode
    public let directives: [DirectiveNode]?
    
    public init(loc: Location?, name: NameNode, directives: [DirectiveNode]?) {
        self.loc = loc
        self.name = name
        self.directives = directives
    }
}

public class InlineFragmentNode: ASTNode, Decodable {
    public var kind: Kind { .INLINE_FRAGMENT }
    public let loc: Location?
    public let typeCondition: NamedTypeNode?
    public let directives: [DirectiveNode]?
    public let selectionSet: SelectionSetNode
    
    public init(loc: Location?, typeCondition: NamedTypeNode?, directives: [DirectiveNode]?, selectionSet: SelectionSetNode) {
        self.loc = loc
        self.typeCondition = typeCondition
        self.directives = directives
        self.selectionSet = selectionSet
    }
}

public class FragmentDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .FRAGMENT_DEFINITION }
    public let loc: Location?
    public let name: NameNode
    public let variableDefinitions: [VariableDefinitionNode]?
    public let typeCondition: NamedTypeNode
    public let directives: [DirectiveNode]?
    public let selectionSet: SelectionSetNode
    
    public init(loc: Location?, name: NameNode, variableDefinitions: [VariableDefinitionNode]?, typeCondition: NamedTypeNode, directives: [DirectiveNode]?, selectionSet: SelectionSetNode) {
        self.loc = loc
        self.name = name
        self.variableDefinitions = variableDefinitions
        self.typeCondition = typeCondition
        self.directives = directives
        self.selectionSet = selectionSet
    }
}

// MARK: Values

public enum ValueNode: Decodable {
    case variable(VariableNode)
    case intValue(IntValueNode)
    case floatValue(FloatValueNode)
    case stringValue(StringValueNode)
    case booleanValue(BooleanValueNode)
    case nullValue(NullValueNode)
    case enumValue(EnumValueNode)
    case listValue(ListValueNode)
    case objectValue(ObjectValueNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .VARIABLE:
            self = .variable(try VariableNode(from: decoder))
        case .INT:
            self = .intValue(try IntValueNode(from: decoder))
        case .FLOAT:
            self = .floatValue(try FloatValueNode(from: decoder))
        case .STRING:
            self = .stringValue(try StringValueNode(from: decoder))
        case .BOOLEAN:
            self = .booleanValue(try BooleanValueNode(from: decoder))
        case .NULL:
            self = .nullValue(try NullValueNode(from: decoder))
        case .ENUM:
            self = .enumValue(try EnumValueNode(from: decoder))
        case .LIST:
            self = .listValue(try ListValueNode(from: decoder))
        case .OBJECT:
            self = .objectValue(try ObjectValueNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unsupported kind for ValueNode")
        }
    }
}

public enum ConstValueNode: Decodable {
    case intValue(IntValueNode)
    case floatValue(FloatValueNode)
    case stringValue(StringValueNode)
    case booleanValue(BooleanValueNode)
    case nullValue(NullValueNode)
    case enumValue(EnumValueNode)
    case constListValue(ConstListValueNode)
    case constObjectValue(ConstObjectValueNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .INT:
            self = .intValue(try IntValueNode(from: decoder))
        case .FLOAT:
            self = .floatValue(try FloatValueNode(from: decoder))
        case .STRING:
            self = .stringValue(try StringValueNode(from: decoder))
        case .BOOLEAN:
            self = .booleanValue(try BooleanValueNode(from: decoder))
        case .NULL:
            self = .nullValue(try NullValueNode(from: decoder))
        case .ENUM:
            self = .enumValue(try EnumValueNode(from: decoder))
        case .LIST:
            self = .constListValue(try ConstListValueNode(from: decoder))
        case .OBJECT:
            self = .constObjectValue(try ConstObjectValueNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unsupported kind for ConstValueNode")
        }
    }
}

public class IntValueNode: ASTNode, Decodable {
    public var kind: Kind { .INT }
    public let loc: Location?
    public let value: String
    
    public init(loc: Location?, value: String) {
        self.loc = loc
        self.value = value
    }
}

public class FloatValueNode: ASTNode, Decodable {
    public var kind: Kind { .FLOAT }
    public let loc: Location?
    public let value: String
    
    public init(loc: Location?, value: String) {
        self.loc = loc
        self.value = value
    }
}

public class StringValueNode: ASTNode, Decodable {
    public var kind: Kind { .STRING }
    public let loc: Location?
    public let value: String
    public let block: Bool?
    
    public init(loc: Location?, value: String, block: Bool?) {
        self.loc = loc
        self.value = value
        self.block = block
    }
}

public class BooleanValueNode: ASTNode, Decodable {
    public var kind: Kind { .BOOLEAN }
    public let loc: Location?
    public let value: Bool
    
    public init(loc: Location?, value: Bool) {
        self.loc = loc
        self.value = value
    }
}

public class NullValueNode: ASTNode, Decodable {
    public var kind: Kind { .NULL }
    public let loc: Location?
    
    public init(loc: Location?) {
        self.loc = loc
    }
}

public class EnumValueNode: ASTNode, Decodable {
    public var kind: Kind { .ENUM }
    public let loc: Location?
    public let value: String
    
    public init(loc: Location?, value: String) {
        self.loc = loc
        self.value = value
    }
}

public class ListValueNode: ASTNode, Decodable {
    public var kind: Kind { .LIST }
    public let loc: Location?
    public let values: [ValueNode]
    
    public init(loc: Location?, values: [ValueNode]) {
        self.loc = loc
        self.values = values
    }
}

public class ConstListValueNode: ASTNode, Decodable {
    public var kind: Kind { .LIST }
    public let loc: Location?
    public let values: [ConstValueNode]
    
    public init(loc: Location?, values: [ConstValueNode]) {
        self.loc = loc
        self.values = values
    }
}

public class ObjectValueNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT }
    public let loc: Location?
    public let fields: [ObjectFieldNode]
    
    public init(loc: Location?, fields: [ObjectFieldNode]) {
        self.loc = loc
        self.fields = fields
    }
}

public class ConstObjectValueNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT }
    public let loc: Location?
    public let fields: [ConstObjectFieldNode]
    
    public init(loc: Location?, fields: [ConstObjectFieldNode]) {
        self.loc = loc
        self.fields = fields
    }
}

public class ObjectFieldNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT_FIELD }
    public let loc: Location?
    public let name: NameNode
    public let value: ValueNode
    
    public init(loc: Location?, name: NameNode, value: ValueNode) {
        self.loc = loc
        self.name = name
        self.value = value
    }
}

public class ConstObjectFieldNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT_FIELD }
    public let loc: Location?
    public let name: NameNode
    public let value: ConstValueNode
    
    public init(loc: Location?, name: NameNode, value: ConstValueNode) {
        self.loc = loc
        self.name = name
        self.value = value
    }
}

/** Directives */

public class DirectiveNode: ASTNode, Decodable {
    public var kind: Kind { .DIRECTIVE }
    public let loc: Location?
    public let name: NameNode
    public let arguments: [ArgumentNode]?
    
    public init(loc: Location?, name: NameNode, arguments: [ArgumentNode]?) {
        self.loc = loc
        self.name = name
        self.arguments = arguments
    }
}

public class ConstDirectiveNode: ASTNode, Decodable {
    public var kind: Kind { .DIRECTIVE }
    public let loc: Location?
    public let name: NameNode
    public let arguments: [ConstArgumentNode]?
    
    public init(loc: Location?, name: NameNode, arguments: [ConstArgumentNode]?) {
        self.loc = loc
        self.name = name
        self.arguments = arguments
    }
}

// MARK: Type Reference

public indirect enum TypeNode: Decodable {
    case named(NamedTypeNode)
    case list(ListTypeNode)
    case nonNull(NonNullTypeNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .NAMED_TYPE:
            self = .named(try NamedTypeNode(from: decoder))
        case .LIST_TYPE:
            self = .list(try ListTypeNode(from: decoder))
        case .NON_NULL_TYPE:
            self = .nonNull(try NonNullTypeNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unsupported kind for TypeNode")
        }
    }
}

public class NamedTypeNode: ASTNode, Decodable {
    public var kind: Kind { .NAMED_TYPE }
    public let loc: Location?
    public let name: NameNode
    
    public init(loc: Location?, name: NameNode) {
        self.loc = loc
        self.name = name
    }
}

public class ListTypeNode: ASTNode, Decodable {
    public var kind: Kind { .LIST_TYPE }
    public let loc: Location?
    public let type: TypeNode
    
    public init(loc: Location?, type: TypeNode) {
        self.loc = loc
        self.type = type
    }
}

public class NonNullTypeNode: ASTNode, Decodable {
    public var kind: Kind { .NON_NULL_TYPE }
    public let loc: Location?
    public let type: TypeNode
    
    public init(loc: Location?, type: TypeNode) {
        self.loc = loc
        self.type = type
    }
}

// MARK: Type System Definition

public enum TypeSystemDefinitionNode: Decodable {
    case schema(SchemaDefinitionNode)
    case type(TypeDefinitionNode)
    case directive(DirectiveDefinitionNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .SCHEMA_DEFINITION:
            self = .schema(try SchemaDefinitionNode(from: decoder))
        case .SCALAR_TYPE_DEFINITION, .OBJECT_TYPE_DEFINITION, .INTERFACE_TYPE_DEFINITION, .UNION_TYPE_DEFINITION, .ENUM_TYPE_DEFINITION, .INPUT_OBJECT_TYPE_DEFINITION:
            self = .type(try TypeDefinitionNode(from: decoder))
        case .DIRECTIVE_DEFINITION:
            self = .directive(try DirectiveDefinitionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unsupported kind for TypeSystemDefinitionNode")
        }
    }
}

public class SchemaDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .SCHEMA_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let directives: [ConstDirectiveNode]?
    public let operationTypes: [OperationTypeDefinitionNode]
    
    public init(loc: Location?, description: StringValueNode?, directives: [ConstDirectiveNode]?, operationTypes: [OperationTypeDefinitionNode]) {
        self.loc = loc
        self.description = description
        self.directives = directives
        self.operationTypes = operationTypes
    }
}

public class OperationTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .OPERATION_TYPE_DEFINITION }
    public let loc: Location?
    public let operation: OperationTypeNode
    public let type: NamedTypeNode
    
    public init(loc: Location?, operation: OperationTypeNode, type: NamedTypeNode) {
        self.loc = loc
        self.operation = operation
        self.type = type
    }
}

// MARK: Type Definition

public enum TypeDefinitionNode: Decodable {
    case scalar(ScalarTypeDefinitionNode)
    case object(ObjectTypeDefinitionNode)
    case interface(InterfaceTypeDefinitionNode)
    case union(UnionTypeDefinitionNode)
    case `enum`(EnumTypeDefinitionNode)
    case inputObject(InputObjectTypeDefinitionNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .SCALAR_TYPE_DEFINITION:
            self = .scalar(try ScalarTypeDefinitionNode(from: decoder))
        case .OBJECT_TYPE_DEFINITION:
            self = .object(try ObjectTypeDefinitionNode(from: decoder))
        case .INTERFACE_TYPE_DEFINITION:
            self = .interface(try InterfaceTypeDefinitionNode(from: decoder))
        case .UNION_TYPE_DEFINITION:
            self = .union(try UnionTypeDefinitionNode(from: decoder))
        case .ENUM_TYPE_DEFINITION:
            self = .enum(try EnumTypeDefinitionNode(from: decoder))
        case .INPUT_OBJECT_TYPE_DEFINITION:
            self = .inputObject(try InputObjectTypeDefinitionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown TypeDefinitionNode kind")
        }
    }
}

public class ScalarTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .SCALAR_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
    }
}

public class ObjectTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let interfaces: [NamedTypeNode]?
    public let directives: [ConstDirectiveNode]?
    public let fields: [FieldDefinitionNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, interfaces: [NamedTypeNode]?, directives: [ConstDirectiveNode]?, fields: [FieldDefinitionNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.interfaces = interfaces
        self.directives = directives
        self.fields = fields
    }
}

public class InterfaceTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .INTERFACE_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let interfaces: [NamedTypeNode]?
    public let directives: [ConstDirectiveNode]?
    public let fields: [FieldDefinitionNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, interfaces: [NamedTypeNode]?, directives: [ConstDirectiveNode]?, fields: [FieldDefinitionNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.interfaces = interfaces
        self.directives = directives
        self.fields = fields
    }
}

public class UnionTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .UNION_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let types: [NamedTypeNode]
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?, types: [NamedTypeNode]) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
        self.types = types
    }
}

public class EnumTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .ENUM_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let values: [EnumValueDefinitionNode]
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?, values: [EnumValueDefinitionNode]) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
        self.values = values
    }
}

public class EnumValueDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .ENUM_VALUE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
    }
}

public class InputObjectTypeDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .INPUT_OBJECT_TYPE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let fields: [InputValueDefinitionNode]
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, directives: [ConstDirectiveNode]?, fields: [InputValueDefinitionNode]) {
        self.loc = loc
        self.description = description
        self.name = name
        self.directives = directives
        self.fields = fields
    }
}

public class FieldDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .FIELD_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let arguments: [InputValueDefinitionNode]?
    public let type: TypeNode
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, arguments: [InputValueDefinitionNode]?, type: TypeNode, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.arguments = arguments
        self.type = type
        self.directives = directives
    }
}

public class InputValueDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .INPUT_VALUE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let type: TypeNode
    public let defaultValue: ConstValueNode?
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, type: TypeNode, defaultValue: ConstValueNode?, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.description = description
        self.name = name
        self.type = type
        self.defaultValue = defaultValue
        self.directives = directives
    }
}

// MARK: Directive Definitions

public class DirectiveDefinitionNode: ASTNode, Decodable {
    public var kind: Kind { .DIRECTIVE_DEFINITION }
    public let loc: Location?
    public let description: StringValueNode?
    public let name: NameNode
    public let arguments: [InputValueDefinitionNode]
    public let repeatable: Bool
    public let locations: [NameNode]
    
    public init(loc: Location?, description: StringValueNode?, name: NameNode, arguments: [InputValueDefinitionNode], repeatable: Bool, locations: [NameNode]) {
        self.loc = loc
        self.description = description
        self.name = name
        self.arguments = arguments
        self.repeatable = repeatable
        self.locations = locations
    }
}

// MARK: Type System Extensions

public enum TypeSystemExtensionNode: Decodable {
    case schema(SchemaExtensionNode)
    case type(TypeExtensionNode)
    
    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .SCHEMA_EXTENSION:
            self = .schema(try SchemaExtensionNode(from: decoder))
        case 
            .SCALAR_TYPE_EXTENSION,
            .OBJECT_TYPE_EXTENSION,
            .INTERFACE_TYPE_EXTENSION,
            .UNION_TYPE_EXTENSION,
            .ENUM_TYPE_EXTENSION,
            .INPUT_OBJECT_TYPE_EXTENSION:
            self = .type(try TypeExtensionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown TypeSystemExtensionNode kind")
        }
    }
}

public class SchemaExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .SCHEMA_EXTENSION }
    public let loc: Location?
    public let directives: [ConstDirectiveNode]?
    public let operationTypes: [OperationTypeDefinitionNode]
    
    public init(loc: Location?, directives: [ConstDirectiveNode]?, operationTypes: [OperationTypeDefinitionNode]) {
        self.loc = loc
        self.directives = directives
        self.operationTypes = operationTypes
    }
}

// MARK: Type Extensions

public enum TypeExtensionNode: Decodable {
    case scalar(ScalarTypeExtensionNode)
    case object(ObjectTypeExtensionNode)
    case interface(InterfaceTypeExtensionNode)
    case union(UnionTypeExtensionNode)
    case enumType(EnumTypeExtensionNode)
    case inputObject(InputObjectTypeExtensionNode)

    private enum CodingKeys: String, CodingKey {
        case kind
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        
        switch kind {
        case .SCALAR_TYPE_EXTENSION:
            self = .scalar(try ScalarTypeExtensionNode(from: decoder))
        case .OBJECT_TYPE_EXTENSION:
            self = .object(try ObjectTypeExtensionNode(from: decoder))
        case .INTERFACE_TYPE_EXTENSION:
            self = .interface(try InterfaceTypeExtensionNode(from: decoder))
        case .UNION_TYPE_EXTENSION:
            self = .union(try UnionTypeExtensionNode(from: decoder))
        case .ENUM_TYPE_EXTENSION:
            self = .enumType(try EnumTypeExtensionNode(from: decoder))
        case .INPUT_OBJECT_TYPE_EXTENSION:
            self = .inputObject(try InputObjectTypeExtensionNode(from: decoder))
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Invalid kind value for TypeExtensionNode")
        }
    }
}

public class ScalarTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .SCALAR_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    
    public init(loc: Location?, name: NameNode, directives: [ConstDirectiveNode]?) {
        self.loc = loc
        self.name = name
        self.directives = directives
    }
}

public class ObjectTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .OBJECT_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let interfaces: [NamedTypeNode]?
    public let directives: [ConstDirectiveNode]?
    public let fields: [FieldDefinitionNode]?
    
    public init(loc: Location?, name: NameNode, interfaces: [NamedTypeNode]?, directives: [ConstDirectiveNode]?, fields: [FieldDefinitionNode]?) {
        self.loc = loc
        self.name = name
        self.interfaces = interfaces
        self.directives = directives
        self.fields = fields
    }
}

public class InterfaceTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .INTERFACE_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let interfaces: [NamedTypeNode]?
    public let directives: [ConstDirectiveNode]?
    public let fields: [FieldDefinitionNode]?
    
    public init(loc: Location?, name: NameNode, interfaces: [NamedTypeNode]?, directives: [ConstDirectiveNode]?, fields: [FieldDefinitionNode]?) {
        self.loc = loc
        self.name = name
        self.interfaces = interfaces
        self.directives = directives
        self.fields = fields
    }
}

public class UnionTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .UNION_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let types: [NamedTypeNode]
    
    public init(loc: Location?, name: NameNode, directives: [ConstDirectiveNode]?, types: [NamedTypeNode]) {
        self.loc = loc
        self.name = name
        self.directives = directives
        self.types = types
    }
}

public class EnumTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .ENUM_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let values: [EnumValueDefinitionNode]
    
    public init(loc: Location?, name: NameNode, directives: [ConstDirectiveNode]?, values: [EnumValueDefinitionNode]) {
        self.loc = loc
        self.name = name
        self.directives = directives
        self.values = values
    }
}

public class InputObjectTypeExtensionNode: ASTNode, Decodable {
    public var kind: Kind { .INPUT_OBJECT_TYPE_EXTENSION }
    public let loc: Location?
    public let name: NameNode
    public let directives: [ConstDirectiveNode]?
    public let fields: [InputValueDefinitionNode]
    
    public init(loc: Location?, name: NameNode, directives: [ConstDirectiveNode]?, fields: [InputValueDefinitionNode]) {
        self.loc = loc
        self.name = name
        self.directives = directives
        self.fields = fields
    }
}
