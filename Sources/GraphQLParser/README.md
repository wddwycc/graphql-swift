# GraphQL AST Parser

It is cumbersome and bug-prone to maintain own parser and keep it up-to-date with the latest spec, this library utilizes [graphql-js-bundler](https://github.com/wddwycc/graphql-js-bundler) to pack and expose the official parser form [graphql/graphql-js](https://github.com/graphql/graphql-js), and run the parser in browser environment, then turn the returned JSON AST into native Swift models.

## How to use

```swift
import GraphQLParser

let parser = try await GraphQLParser()
let documentNode = try await parser.parse(source: $GRAPHQL_DOCUMENT_STRING)
```
