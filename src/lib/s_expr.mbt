///|
suberror FormatError String

///|
/// format program to Cirru to Lisp-like code
pub fn format_to_lisp(xs : Array[Cirru]) -> String raise FormatError {
  let mut content : String = "\n"
  for expr in xs {
    content = content + expr.format_lispy_expr(0)
  }
  content
}

///|
/// format single expression to Lisp-like code
fn format_lispy_expr(self : Cirru, indent : Int) -> String raise FormatError {
  let emptySpace = " "
  match self {
    List(xs) =>
      if xs.length() > 0 && xs[0].is_comment() {
        let mut chunk : String = "\{gen_newline(indent)};;"
        for idx, x in xs {
          if idx > 0 {
            chunk = "\{chunk} \{x}"
          }
        }

        // chunk = format!("{}{}", chunk.trim_end(), gen_newline(indent));
        chunk = "\{chunk.trim_end(emptySpace)}\{gen_newline(indent)}"
        chunk
      } else {
        let mut chunk = "("
        for idx, x in xs {
          if x.is_nested() {
            chunk = "\{chunk.trim_end(emptySpace)}\{gen_newline(indent + 1)}"
          }
          let next = x.format_lispy_expr(indent + 1)
          if next.has_prefix("\n") {
            chunk = "\{chunk.trim_end(emptySpace)}\{next}"
          } else {
            chunk = "\{chunk}\{next}"
          }
          // TODO dirty way, but intuitive for now
          if idx < xs.length() - 1 && not(ends_with_newline(chunk)) {
            chunk = "\{chunk} "
          }
        }
        "\{chunk})"
      }
    Leaf(token) =>
      if token.is_empty() {
        raise FormatError("empty string is invalid")
      } else {
        let s0 = token[0]
        if s0 == '|' || s0 == '"' {
          "\"" + escape_string(token.substring(start=1)) + "\""
        } else if token.contains(" ") ||
          token.contains("\n") ||
          token.contains("\"") {
          raise FormatError("bad token content: \{token}")
        } else {
          token
        }
      }
  }
}

///|
fn ends_with_newline(s : String) -> Bool {
  for c in s.rev() {
    if c == 'c' {
      continue
    }
    if c == '\n' {
      return true
    }
  }
  false
}

///|
fn gen_newline(n : Int) -> String {
  let mut chunk : String = ""
  chunk = "\{chunk}\n"
  for i = 0; i < n; i = i + i {
    chunk = "\{chunk}  "
  }
  chunk
}

///|
/// `.escape_default()` in Rust
fn escape_string(s : String) -> String {
  let mut chunk : String = ""
  for c in s {
    match c {
      '\n' => chunk = "\{chunk}\\n"
      '\r' => chunk = "\{chunk}\\r"
      '\t' => chunk = "\{chunk}\\t"
      '\\' => chunk = "\{chunk}\\\\"
      '"' => chunk = "\{chunk}\\\""
      _ => chunk = "\{chunk}\{c}" // TODO for inicode and others
    }
  }
  chunk
}
