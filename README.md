# Cirru Parser in Moonbit

Docs: https://mooncakes.io/docs/#/tiye/cirru-parser/lib/members

```bash
moon add tiye/cirru-parser
```

import in `moon.pkg.json`:

```js
    {
      "path": "tiye/cirru-parser",
      "alias": "cirru_parser"
    }
```

```moonbit
using @cirru_parser {type Cirru}

// parse Cirru code
Cirru::parse(code: String) : Array[Cirru] raise CirruParseError

// parse a one-line Cirru expression
Cirru::parse_expr_one_liner(code: String) : Cirru raise CirruParseError

// format Cirru code
Cirru::format(cirru: Array[Cirru], use_inline=false) : String raise FormatCirruError

// format one expression into one line
Cirru::format_expr_one_liner(expr: Cirru) : String raise FormatCirruError
Cirru::format_one_liner(expr: Cirru) : String raise FormatCirruError
```

### License

Apache-2.0
