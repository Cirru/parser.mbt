///|
fn build_exprs(
  tokens : Array[CirruLexItem]
) -> Array[Cirru] raise CirruParseError {
  let acc : Array[Cirru] = Array::new()
  let mut idx = 0
  let pull_token = fn() -> CirruLexItem? {
    // println("pulling token at \{idx}")
    if idx >= tokens.length() {
      return None
    }
    let pos = idx
    idx += 1
    Some(tokens[pos])
  }
  for {
    let chunk = pull_token()
    match chunk {
      None => return acc
      Some(ck) =>
        match ck {
          Open => {
            let mut pointer : Array[Cirru] = Array::new(capacity=8)
            // guess a nested level of 16
            let pointer_stack : Array[Array[Cirru]] = Array::new(capacity=16)
            for {
              let cursor = pull_token()
              match cursor {
                None => raise CirruParseError("unexpected end of file")
                Some(c) =>
                  match c {
                    Close =>
                      match pointer_stack.pop() {
                        None => {
                          acc.push(List(pointer))
                          break
                        }
                        Some(v) => {
                          let prev_p = pointer
                          pointer = v
                          pointer.push(List(prev_p))
                        }
                      }
                    Open => {
                      pointer_stack.push(pointer)
                      pointer = Array::new()
                    }
                    Str(s) => pointer.push(Leaf(s))
                    Indent(n) => raise CirruParseError("unknown indent: \{n}")
                  }
              }
            }
          }
          Close => raise CirruParseError("unexpected \")\"")
          a => raise CirruParseError("unknown item: \{a}")
        }
    }
  }
}

///| main function to parse Cirru code into syntax tree
pub fn Cirru::parse(code : String) -> Array[Cirru] raise CirruParseError {
  let tokens = resolve_indentations(lex(code))
  // println("tokens: \{tokens}")
  let tree = build_exprs(tokens)
  // println("tree: \{tree}")
  resolve_comma(resolve_dollar(tree))
}

///|
suberror CirruParseError String

///| display Cirru parse error
pub fn to_string(self : CirruParseError) -> String {
  match self {
    CirruParseError(s) => s
  }
}

///|
fn parse_indentation(size : Int) -> CirruLexItem raise CirruParseError {
  if size % 2 == 0 {
    Indent(size >> 1)
  } else {
    raise CirruParseError("odd indentation size: \{size}")
  }
}

///| lexer is a simpler state machine to tokenize Cirru code
fn lex(initial_code : String) -> Array[CirruLexItem] raise CirruParseError {
  let acc = []
  let mut state : CirruLexState = Indent
  let mut buffer = ""
  let code = initial_code.to_array()
  for idx, c in code {
    // println("acc: \{acc}")
    // println(
    //   "lexing \{c.to_string().escape()} in \{state} and \{buffer.escape()}",
    // )
    match state {
      Space =>
        match c {
          ' ' => {
            state = Space
            buffer = ""
          }
          '\n' => {
            state = Indent
            buffer = ""
          }
          '(' => {
            acc.push(Open)
            state = Space
            buffer = ""
          }
          ')' => {
            acc.push(Close)
            state = Space
            buffer = ""
          }
          '"' => {
            state = Str
            buffer = ""
          }
          _ => {
            state = Token
            buffer = c.to_string()
          }
        }
      Token =>
        match c {
          ' ' => {
            acc.push(Str(buffer))
            state = Space
            buffer = ""
          }
          '"' => {
            acc.push(Str(buffer))
            state = Str
            buffer = ""
          }
          '\n' => {
            acc.push(Str(buffer))
            state = Indent
            buffer = ""
          }
          '(' => {
            acc.push(Str(buffer))
            acc.push(Open)
            state = Space
            buffer = ""
          }
          ')' => {
            acc.push(Str(buffer))
            acc.push(Close)
            state = Space
            buffer = ""
          }
          _ => {
            state = Token
            buffer += c.to_string()
          }
        }
      Str =>
        match c {
          '"' => {
            acc.push(Str(buffer))
            state = Space
            buffer = ""
          }
          '\\' => state = Escape
          '\n' => raise CirruParseError("unexpected newline in string")
          _ => {
            state = Str
            buffer += c.to_string()
          }
        }
      Escape =>
        match c {
          '"' => {
            state = Str
            buffer += "\""
          }
          '\'' => {
            state = Str
            buffer += "'"
          }
          't' => {
            state = Str
            buffer += "\t"
          }
          'n' => {
            state = Str
            buffer += "\n"
          }
          'r' => {
            state = Str
            buffer += "\r"
          }
          'u' => {
            // TODO handle some unicode
            let end = idx + 10
            let peek = if end >= code.length() {
              code[idx:]
            } else {
              code[idx:end]
            }
            let mut preview = ""
            for c in peek {
              preview += c.to_string()
            }
            println("Unicode escaping is not supported yet: \{preview} ...")
            buffer += "\\u"
            state = Str
          }
          '\\' => {
            state = Str
            buffer += "\\"
          }
          _ =>
            raise CirruParseError(
              "unexpected character during string escaping: \{c}",
            )
        }
      Indent =>
        match c {
          ' ' => {
            state = Indent
            buffer += c.to_string()
          }
          '\n' => {
            state = Indent
            buffer = ""
          }
          '"' => {
            let level = parse_indentation(buffer.length())
            acc.push(level)
            state = Str
            buffer = ""
          }
          '(' => {
            let level = parse_indentation(buffer.length())
            acc.push(level)
            acc.push(CirruLexItem::Open)
            state = Space
            buffer = ""
          }
          ')' => raise CirruParseError("unexpected ) at line start")
          _ => {
            let level = parse_indentation(buffer.length())
            acc.push(level)
            state = Token
            buffer = c.to_string()
          }
        }
    }
  }
  // println("end of file in lex \{acc}")
  match state {
    Space => acc
    Token => {
      acc.push(CirruLexItem::Str(buffer))
      acc
    }
    Escape => raise CirruParseError("unknown escape")
    Indent => acc
    Str => raise CirruParseError("finished at string")
  }
}

///| internal function for figuring out indentations after lexing
fn resolve_indentations(tokens : Array[CirruLexItem]) -> Array[CirruLexItem] {
  let size = tokens.length()
  let mut acc : Array[CirruLexItem] = Array::new()
  let mut level = 0
  let mut pointer = 0
  for {
    if pointer >= size {
      if acc.is_empty() {
        return Array::new()
      }
      acc.insert(0, Open)
      for i = 0; i < level; i = i + 1 {
        acc.push(Close)
      }
      acc.push(Close)
      return acc
    }
    match tokens[pointer] {
      Str(s) => {
        acc.push(Str(s))
        pointer += 1
      }
      Open => {
        acc.push(Open)
        pointer += 1
      }
      Close => {
        acc.push(Close)
        pointer += 1
      }
      Indent(n) =>
        if n > level {
          let delta = n - level
          // for _ in 0..delta {
          for i = 0; i < delta; i = i + 1 {
            acc.push(Open)
          }
          pointer += 1
          level = n
        } else if n < level {
          let delta = level - n
          // for _ in 0..delta {
          for i = 0; i < delta; i = i + 1 {
            acc.push(Close)
          }
          acc.push(Close)
          acc.push(Open)
          pointer += 1
          level = n
        } else {
          if acc.is_empty() {
            acc = Array::new()
          } else {
            acc.push(Close)
            acc.push(Open)
          }
          pointer += 1
        }
    }
  }
}
