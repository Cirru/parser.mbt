
fn build_exprs(tokens: @vec.Vec[CirruLexItem]) -> Result[@vec.Vec[Cirru], String] {
  let a = [1,2,3]
  Result::Err("TODO")
}


pub fn parse(content: String) -> Result[Cirru, String] {
  // @seq::Seq::from_string(content)
  let ss = @peter_seq.Seq::from_string(content)
  loop ss.0() {
    Some((c, xss)) => {
      debug(c)
      continue xss.0()
    }
    None => break
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
  let mut acc: @vec.Vec[CirruLexItem] = @vec.Vec::new()
  let mut state = CirruLexState::Indent
  let mut buffer = ""
  let code = @peter_seq.Seq::from_string(initial_code)
  loop code.0(), 0 {
    None, _idx => break
    Some((c, xss)), idx => {
      match state {
        CirruLexState::Space => {
          match c {
            ' ' => {
              state = CirruLexState::Space
              buffer = ""
              continue xss.0(), idx + 1
            }
            '\n' => {
              state = CirruLexState::Indent
              buffer = ""
              continue xss.0(), idx + 1
            }
            '(' => {
              acc.push(CirruLexItem::Open)
              state = CirruLexState::Space
              buffer = ""
              continue xss.0(), idx + 1
            }
            ')' => {
              acc.push(CirruLexItem::Close)
              state = CirruLexState::Space
              buffer = ""
              continue xss.0(), idx + 1
            }
            '"' => {
              state = CirruLexState::Str
              buffer = ""
              continue xss.0(), idx + 1
            }
            _ => {
              state = CirruLexState::Token
              buffer = c.to_string()
              continue xss.0(), idx + 1
            }
          }
        }
        CirruLexState::Token => {
          // TODO
        }
        _ => {
          // TODO: handle space
        }
      }
    }

  }

  Ok(acc)
}