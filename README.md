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

// format Cirru code
Cirru::format(cirru: Array[Cirru], use_inline=false) : String raise FormatCirruError
```

### License

Apache-2.0
