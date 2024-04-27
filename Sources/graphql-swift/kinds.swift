//
//  File.swift
//
//
//  Created by Wen Duan on 2024/04/27.
//

public enum Kind: String, Decodable {
  /** Name */
  case NAME = "Name"

  /** Document */
  case DOCUMENT = "Document"
  case OPERATION_DEFINITION = "OperationDefinition"
  case VARIABLE_DEFINITION = "VariableDefinition"
  case SELECTION_SET = "SelectionSet"
  case FIELD = "Field"
  case ARGUMENT = "Argument"

  /** Fragments */
  case FRAGMENT_SPREAD = "FragmentSpread"
  case INLINE_FRAGMENT = "InlineFragment"
  case FRAGMENT_DEFINITION = "FragmentDefinition"

  /** Values */
  case VARIABLE = "Variable"
  case INT = "IntValue"
  case FLOAT = "FloatValue"
  case STRING = "StringValue"
  case BOOLEAN = "BooleanValue"
  case NULL = "NullValue"
  case ENUM = "EnumValue"
  case LIST = "ListValue"
  case OBJECT = "ObjectValue"
  case OBJECT_FIELD = "ObjectField"

  /** Directives */
  case DIRECTIVE = "Directive"

  /** Types */
  case NAMED_TYPE = "NamedType"
  case LIST_TYPE = "ListType"
  case NON_NULL_TYPE = "NonNullType"

  /** Type System Definitions */
  case SCHEMA_DEFINITION = "SchemaDefinition"
  case OPERATION_TYPE_DEFINITION = "OperationTypeDefinition"

  /** Type Definitions */
  case SCALAR_TYPE_DEFINITION = "ScalarTypeDefinition"
  case OBJECT_TYPE_DEFINITION = "ObjectTypeDefinition"
  case FIELD_DEFINITION = "FieldDefinition"
  case INPUT_VALUE_DEFINITION = "InputValueDefinition"
  case INTERFACE_TYPE_DEFINITION = "InterfaceTypeDefinition"
  case UNION_TYPE_DEFINITION = "UnionTypeDefinition"
  case ENUM_TYPE_DEFINITION = "EnumTypeDefinition"
  case ENUM_VALUE_DEFINITION = "EnumValueDefinition"
  case INPUT_OBJECT_TYPE_DEFINITION = "InputObjectTypeDefinition"

  /** Directive Definitions */
  case DIRECTIVE_DEFINITION = "DirectiveDefinition"

  /** Type System Extensions */
  case SCHEMA_EXTENSION = "SchemaExtension"

  /** Type Extensions */
  case SCALAR_TYPE_EXTENSION = "ScalarTypeExtension"
  case OBJECT_TYPE_EXTENSION = "ObjectTypeExtension"
  case INTERFACE_TYPE_EXTENSION = "InterfaceTypeExtension"
  case UNION_TYPE_EXTENSION = "UnionTypeExtension"
  case ENUM_TYPE_EXTENSION = "EnumTypeExtension"
  case INPUT_OBJECT_TYPE_EXTENSION = "InputObjectTypeExtension"
}
