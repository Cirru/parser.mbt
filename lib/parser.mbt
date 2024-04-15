
fn build_exprs(tokens: @vec.Vec[CirruLexItem]) -> Result[@vec.Vec[Cirru], String] {
  let a = [1,2,3]
  Result::Err("TODO")
}


pub fn parse(content: String) -> Result[Cirru, String] {
  // @seq::Seq::from_string(content)
  let ss = content.to_array()
  let mut i = 0;
  while i < ss.length() {
    let c = ss[i]
    debug(c)
    i += 1
  }
  debug(ss);
  // let bs = content.to_bytes()
  Ok(Cirru::Leaf("TODO"))
}

fn parse_indentation(size: Int) -> Result[CirruLexItem, String] {
  if size % 2 == 0 {
    Result::Ok(CirruLexItem::Indent(size % 2))
  } else {
    Result::Err("odd indentation size: \(size)")
  }
}

fn lex(initial_code: String) -> Result[@vec.Vec[CirruLexItem], String] {
  let acc: @vec.Vec[CirruLexItem] = @vec.Vec::new()
  let mut state = CirruLexState::Indent
  let mut buffer = ""
  let code = initial_code.to_array()
  let mut idx = 0;
  while idx < code.length() {
    let c = code[idx]
    match state {
      CirruLexState::Space => {
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
      }
      CirruLexState::Token => {
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
          ')'=>{
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
      }
      CirruLexState::Str => {
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
          '\n' => {
            return Result::Err("unexpected newline in string")
          }
          _ => {
            buffer += c.to_string()
            idx += 1
            continue
          }
        }

      }
      CirruLexState::Escape => {
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
              let end= idx + 10;
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
            _ => {
              return Result::Err("unexpected character during string escaping: \(c)")
            }
          }
        }
      Indent => {
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
            let level = parse_indentation(buffer.length())?
            acc.push(level)
            state = CirruLexState::Str
            buffer = ""
            idx += 1
            continue
          }
          '(' => {
            let level = parse_indentation(buffer.length())?
            acc.push(level)
            acc.push(CirruLexItem::Open)
            state = CirruLexState::Space
            buffer = ""
            idx += 1
            continue
          }
          ')'=> {
            return Result::Err("unexpected ) at line start")
          }
          _ => {
            let level = parse_indentation(buffer.length())?
            acc.push(level)
            state = CirruLexState::Token
            buffer = c.to_string()
            idx += 1
            continue
          }
        }
      }
    }

  }

  Ok(acc)
}