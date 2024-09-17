/// Cirru uses nested Vecters and Strings as data structure
pub enum Cirru {
  /// Leaf node, with a string
  Leaf(String)
  /// List node, with a list of children
  List(Array[Cirru])
} derive(Eq)

pub impl Hash for Cirru with hash(self) {
  let mut i = 0
  match self {
    Cirru::Leaf(s) => i = s.length()
    Cirru::List(xs) =>
      for _ in xs {
        i = i + 1 // TODO: how to hash a list?
      }
  }
  i
}

pub impl Hash for Cirru with hash_combine(self, hasher) {
  match self {
    Cirru::Leaf(s) => hasher.combine_string(s)
    Cirru::List(xs) =>
      for x in xs {
        hasher.combine(x)
      }
  }
}

pub fn to_json(self : Cirru) -> Json {
  match self {
    Cirru::Leaf(s) => Json::String(s)
    Cirru::List(xs) => {
      let out = Array::new()
      for x in xs {
        out.push(x.to_json())
      }
      Json::Array(out)
    }
  }
}

pub impl @json.FromJson for Cirru with from_json(json, path) {
  match json {
    String(a) => Cirru::Leaf(a)
    Array(xs) => {
      let ys = []
      for idx, x in xs {
        let v = @json.FromJson::from_json!(x, path.add_index(idx))
        ys.push(v)
      }
      Cirru::List(ys)
    }
    // _ => @json.decode_error!((path, "Char::from_json: expected string"))
    _ =>
      raise @json.JsonDecodeError(
        (path, "Cirru::from_json: expected string or array"),
      )
  }
}

fn Cirru::default() -> Cirru {
  Cirru::List(Array::new())
}

pub fn output(self : Cirru, logger : Logger) -> Unit {
  logger.write_string(self.to_string())
}

pub fn to_string(self : Cirru) -> String {
  match self {
    Cirru::Leaf(s) =>
      if CirruLexItem::is_normal_str(s) {
        return s
      } else {
        return escape_cirru_leaf(s)
      }
    Cirru::List(xs) => {
      let mut out = ""
      for i = 0; i < xs.length(); i = i + 1 {
        let x = xs[i]
        out = "\{out}\{x}"
        if i < xs.length() - 1 {
          out = "\{out} "
        }
      }
      return out
    }
  }
}

pub fn debug_write(self : Cirru, buffer : Buffer) -> Unit {
  match self {
    Cirru::Leaf(s) => buffer.write_string(s)
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

pub fn length(self : Cirru) -> Int {
  match self {
    Leaf(s) => s.length()
    List(xs) => xs.length()
  }
}

pub fn is_empty(self : Cirru) -> Bool {
  match self {
    Leaf(s) => s.length() == 0
    List(xs) => xs.length() == 0
  }
}

pub fn is_nested(self : Cirru) -> Bool {
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

pub fn is_comment(self : Cirru) -> Bool {
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
} derive(Show)

enum CirruLexItem {
  Open
  Close
  Indent(Int)
  Str(String)
}

fn output(self : CirruLexItem, logger : Logger) -> Unit {
  logger.write_string(self.to_string())
}

fn to_string(self : CirruLexItem) -> String {
  match self {
    CirruLexItem::Open => "("
    CirruLexItem::Close => ")"
    CirruLexItem::Indent(size) => "indent(\{size})"
    CirruLexItem::Str(s) => s
  }
}

fn CirruLexItem::is_normal_str(tok : String) -> Bool {
  let size = tok.length()
  if size == 0 {
    return false
  }
  let mut i = 0
  while i < size {
    let c = tok[i]
    if (c >= 'A' && c <= 'Z') ||
      (c >= 'a' && c <= 'z') ||
      c == '-' ||
      c == '?' ||
      c == '!' ||
      c == '+' ||
      c == '*' ||
      c == '$' ||
      c == '@' ||
      c == '#' ||
      c == '%' ||
      c == '&' ||
      c == '_' ||
      c == '=' ||
      c == '|' ||
      c == ':' ||
      c == '.' ||
      c == '<' ||
      c == '>' {
      i = i + 1
    } else {
      return false
    }
    i = i + 1
  }
  return true
}

fn escape_cirru_leaf(s : String) -> String {
  if is_normal_str(s) {
    return "\"\{s}\""
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
        out = "\{out}\{c}"
      }
      i = i + 1
    }
    out = out + "\""
    return out
  }
}
