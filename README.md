# Cirru Parser in Moonbit

Docs: https://mooncakes.io/docs/#/tiye/cirru-parser/lib/members

```bash
moon add tiye/cirru-parser
```

```moonbit
typealias @cirru_parser.Cirru

// parse Cirru code
Cirru::parse(code: String) : Array[Cirru]!CirruParseError

// format Cirru code
Cirru::format(cirru: Array[Cirru], {use_inline: false}) : String!FormatCirruError
```

### License

Apache-2.0
