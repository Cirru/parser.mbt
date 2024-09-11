fn build_exprs(tokens : Array[CirruLexItem]) -> Array[Cirru]!CirruParseError {
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
          CirruLexItem::Open => {
            let mut pointer : Array[Cirru] = Array::new()
            // guess a nested level of 16
            let pointer_stack : Array[Array[Cirru]] = Array::new()
            for {
              let cursor = pull_token()
              match cursor {
                None => raise CirruParseError("unexpected end of file")
                Some(c) =>
                  match c {
                    CirruLexItem::Close =>
                      match pointer_stack.pop() {
                        None => {
                          acc.push(Cirru::List(pointer))
                          break
                        }
                        Some(v) => {
                          let prev_p = pointer
                          pointer = v
                          pointer.push(Cirru::List(prev_p))
                        }
                      }
                    CirruLexItem::Open => {
                      pointer_stack.push(pointer)
                      pointer = Array::new()
                    }
                    CirruLexItem::Str(s) => pointer.push(Cirru::Leaf(s))
                    CirruLexItem::Indent(n) =>
                      raise CirruParseError("unknown indent: \{n}")
                  }
              }
            }
          }
          CirruLexItem::Close => raise CirruParseError("unexpected \")\"")
          a => raise CirruParseError("unknown item: \{a}")
        }
    }
  }
}

pub fn parse(code : String) -> Array[Cirru]!CirruParseError {
  let tokens = resolve_indentations(lex!(code))
  println("tokens: \{tokens}")
  let tree = build_exprs!(tokens)
  println("tree: \{tree}")
  resolve_comma(resolve_dollar(tree))
}

type! CirruParseError String

pub fn to_string(self : CirruParseError) -> String {
  match self {
    CirruParseError(s) => s
  }
}

fn parse_indentation(size : Int) -> CirruLexItem!CirruParseError {
  if size % 2 == 0 {
    CirruLexItem::Indent(size % 2)
  } else {
    raise CirruParseError("odd indentation size: \{size}")
  }
}

fn lex(initial_code : String) -> Array[CirruLexItem]!CirruParseError {
  let acc = []
  let mut state = CirruLexState::Indent
  let mut buffer = ""
  let code = initial_code.to_array()
  let mut idx = 0
  while idx < code.length() {
    let c = code[idx]
    // println("lexing \{c} in \{state} and \{buffer}")
    match state {
      CirruLexState::Space =>
        match c {
          ' ' => {
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          '\n' => {
            state = CirruLexState::Indent
            buffer = ""
            idx += 1
            continue
          }
          '(' => {
            acc.push(CirruLexItem::Open)
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          ')' => {
            acc.push(CirruLexItem::Close)
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          '"' => {
            state = CirruLexState::Str
            buffer = ""
            idx += 1
            continue
          }
          _ => {
            state = CirruLexState::Token
            buffer = c.to_string()
            idx += 1
            continue
          }
        }
      CirruLexState::Token =>
        match c {
          ' ' => {
            acc.push(CirruLexItem::Str(buffer))
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          '"' => {
            acc.push(CirruLexItem::Str(buffer))
            state = CirruLexState::Str
            buffer = ""
            idx += 1
            continue
          }
          '\n' => {
            acc.push(CirruLexItem::Str(buffer))
            state = CirruLexState::Indent
            buffer = ""
            idx += 1
            continue
          }
          '(' => {
            acc.push(CirruLexItem::Str(buffer))
            acc.push(CirruLexItem::Open)
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          ')' => {
            acc.push(CirruLexItem::Str(buffer))
            acc.push(CirruLexItem::Close)
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          _ => {
            buffer += c.to_string()
            idx += 1
            continue
          }
        }
      CirruLexState::Str =>
        match c {
          '"' => {
            acc.push(CirruLexItem::Str(buffer))
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          '\\' => {
            state = CirruLexState::Escape
            buffer = ""
            idx += 1
            continue
          }
          '\n' => raise CirruParseError("unexpected newline in string")
          _ => {
            buffer += c.to_string()
            idx += 1
            continue
          }
        }
      CirruLexState::Escape =>
        match c {
          '"' => {
            state = CirruLexState::Str
            buffer += "\""
            idx += 1
            continue
          }
          '\'' => {
            state = CirruLexState::Str
            buffer += "'"
            idx += 1
            continue
          }
          't' => {
            state = CirruLexState::Str
            buffer += "\t"
            idx += 1
            continue
          }
          'n' => {
            state = CirruLexState::Str
            buffer += "\n"
            idx += 1
            continue
          }
          'r' => {
            state = CirruLexState::Str
            buffer += "\r"
            idx += 1
            continue
          }
          'u' => {
            let end = idx + 10
            // TODO
            buffer += "\\u"
            state = CirruLexState::Str
            idx += 1
            continue
          }
          '\\' => {
            state = CirruLexState::Str
            buffer += "\\"
            idx += 1
            continue
          }
          _ =>
            raise CirruParseError(
              "unexpected character during string escaping: \{c}",
            )
        }
      Indent =>
        match c {
          ' ' => {
            state = CirruLexState::Indent
            buffer += c.to_string()
            idx += 1
            continue
          }
          '\n' => {
            state = CirruLexState::Indent
            buffer += ""
            idx += 1
            continue
          }
          '"' => {
            let level = parse_indentation!(buffer.length())
            acc.push(level)
            state = CirruLexState::Str
            buffer = ""
            idx += 1
            continue
          }
          '(' => {
            let level = parse_indentation!(buffer.length())
            acc.push(level)
            acc.push(CirruLexItem::Open)
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          ')' => raise CirruParseError("unexpected ) at line start")
          _ => {
            let level = parse_indentation!(buffer.length())
            acc.push(level)
            state = CirruLexState::Token
            buffer = c.to_string()
            idx += 1
            continue
          }
        }
    }
  }
  println("end of file in lex \{acc}")
  match state {
    CirruLexState::Space => acc
    CirruLexState::Token => {
      acc.push(CirruLexItem::Str(buffer))
      acc
    }
    CirruLexState::Escape => raise CirruParseError("unknown escape")
    CirruLexState::Indent => acc
    CirruLexState::Str => raise CirruParseError("finished at string")
  }
}

/// internal function for figuring out indentations after lexing
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
      acc.insert(0, CirruLexItem::Open)
      for i = 0; i < level; i = i + 1 {
        acc.push(CirruLexItem::Close)
      }
      acc.push(CirruLexItem::Close)
      return acc
    }
    match tokens[pointer] {
      CirruLexItem::Str(s) => {
        acc.push(CirruLexItem::Str(s))
        pointer += 1
      }
      CirruLexItem::Open => {
        acc.push(CirruLexItem::Open)
        pointer += 1
      }
      CirruLexItem::Close => {
        acc.push(CirruLexItem::Close)
        pointer += 1
      }
      CirruLexItem::Indent(n) =>
        if n > level {
          let delta = n - level
          // for _ in 0..delta {
          for i = 0; i < delta; i = i + 1 {
            acc.push(CirruLexItem::Open)
          }
          pointer += 1
          level = n
        } else if n < level {
          let delta = level - n
          // for _ in 0..delta {
          for i = 0; i < delta; i = i + 1 {
            acc.push(CirruLexItem::Close)
          }
          acc.push(CirruLexItem::Close)
          acc.push(CirruLexItem::Open)
          pointer += 1
          level = n
        } else {
          if acc.is_empty() {
            acc = Array::new()
          } else {
            acc.push(CirruLexItem::Close)
            acc.push(CirruLexItem::Open)
          }
          pointer += 1
        }
    }
  }
}
