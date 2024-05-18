# README

An example project to show the power of the codegen tool. 

## How to run

At the root folder of the project, run:

```shell
swift run graphql-codegen \
  --schema https://countries.trevorblades.com \
  --documents Examples/codegen/documents \
  --output Examples/codegen/generated
```

Then `/generated` folder would get updated based on GraphQL documents defined in `/documents` folder.
