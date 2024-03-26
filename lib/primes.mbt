
/// Cirru uses nested Vecters and Strings as data structure
enum Cirru {
  /// Leaf node, with a string
  Leaf(String)
  /// List node, with a list of children
  List(@vec.Vec[Cirru])
}

fn Cirru::default() -> Cirru {
  Cirru::List(@vec.Vec::new())
}

fn to_string(self: Cirru) -> String {
  match self {
    Cirru::Leaf(s) => s
    Cirru::List(xs) => {
      let mut out = ""
      for i = 0; i < xs.length(); i = i + 1 {
        let x = xs[i]
        out = "\(out)\(x)"
        if i < xs.length() - 1 {
          out = "\(out) "
        }
      }
      return out
    }
  }
}

pub fn debug_write(self: Cirru, buffer: Buffer) -> Unit {
  match self {
    Cirru::Leaf(s) => {
      buffer.write_string(s)
    }
    Cirru::List(xs) => {
      buffer.write_char('(')
      for i = 0; i < xs.length(); i = i + 1 {
        let x = xs[i]
        buffer.write_string(x.to_string())
        if i < xs.length() - 1 {
          buffer.write_char(' ')
        }
      }
      buffer.write_char(')')
    }
  }
}

fn op_equal(self: Cirru, other: Cirru) -> Bool {
  match self {
    Cirru::Leaf(a) => match other {
      Cirru::Leaf(b) => a == b
      _ => false
    }
    Cirru::List(xs) => match other {
      Cirru::List(ys) => {
        if xs.length() != ys.length() {
          return false
        }
        let size = xs.length()
        let mut i = 0
        while i <= size {
          if xs[i] != ys[i] {
            return false
          }
          i = i + 1
        }
        return true
      }
      _ => false
    }
  }
}

pub fn length(self: Cirru) -> Int {
  match self {
    Leaf(s) => s.length()
    List(xs) => xs.length()
  }
}

pub fn is_empty(self: Cirru) -> Bool {
  match self {
    Leaf(s) => s.length() == 0
    List(xs) => xs.length() == 0
  }
}

pub fn is_nested(self: Cirru)-> Bool{
  match self {
    Leaf(_) => false
    List(xs) => {
      for i = 0; i < xs.length(); i = i + 1 {
        let x = xs[i]
        if x.is_nested() {
          return true
        }
      }
      return false
    }
  }
}

pub fn is_comment(self: Cirru) -> Bool {
  match self {
    Leaf(s) => s[0] == ';'
    _ => false
  }
}

enum CirruLexState {
  Space
  Token
  Escape
  Indent
  Str
} derive(Debug)

enum CirruLexItem {
  Open
  Close
  Indent(Int)
  Str(String)
}

fn CirruLexItem::is_normal_str(tok: String) -> Bool {
  let size = tok.length()
  if size == 0 {
    return false
  }
  let mut i = 0
  while i < size {
    let c = tok[i]
    if (c >= 'A' && c <= 'Z') || (c>='a' && c <= 'z') || c == '-' || c == '?' || c == '!' || c == '+' || c == '*' || c == '$' || c == '@' || c == '#' || c == '%' || c == '&' || c == '_' || c == '=' || c == '|' || c == ':' || c == '.' || c == '<' || c == '>' {
      i = i + 1
    } else {
      return false
    }
    i = i + 1
  }
  return true

}

fn escape_cirru_leaf(s: String) -> String {

  if is_normal_str(s) {
    return "\"\(s)\""
  } else {
    let mut out = "\""
    let size = s.length()
    let mut i = 0
    while i < size {
      let c = s[i]
      if c == '\n' {
        out = out + "\\n"
      } else if c == '\t' {
        out = out + "\\t"
      } else if c == '"' {
        out = out + "\\\""
      } else if c == '\\' {
        out = out + "\\\\"
      } else if c == '\'' {
        out = out + "\\'"
      } else {
        out = "\(out)\(c)"
      }
      i = i + 1
    }
    out = out + "\""
    return out
  }
}