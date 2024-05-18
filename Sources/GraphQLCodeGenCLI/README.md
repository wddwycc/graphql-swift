# GraphQL Code Generator

This is a GraphQL Code Generator, similar to [dotansimha/graphql-code-generator](https://github.com/dotansimha/graphql-code-generator), can be used to generate Swift Codable models for GraphQL request and response payload. 

> Since project is still in its eary stage, I can't guarantee this CLI tool will be free of breaking changes.

## How to install

For now, this CLI tool only support build and install from source. At root of the project, run:

```shell
swift build -c release
```

You will get the executable at `.build/release/graphql-codegen`

## How to use

Please refer to [This Example Project](/Examples/codegen/README.md)
