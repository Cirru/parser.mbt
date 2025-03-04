///| Cirru uses nested Vecters and Strings as data structure
pub(all) enum Cirru {
  /// Leaf node, with a string
  Leaf(String)
  /// List node, with a list of children
  List(Array[Cirru])
} derive(Eq)

///|
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

///|
pub impl Hash for Cirru with hash_combine(self, hasher) {
  match self {
    Cirru::Leaf(s) => hasher.combine_string(s)
    Cirru::List(xs) =>
      for x in xs {
        hasher.combine(x)
      }
  }
}

///|
pub impl ToJson for Cirru with to_json(self : Cirru) -> Json {
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

///|
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

///|
fn Cirru::default() -> Cirru {
  Cirru::List(Array::new())
}

///|
pub impl Show for Cirru with output(self : Cirru, logger : &Logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
pub fn Cirru::to_string(self : Cirru) -> String {
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

///|
pub fn compare(self : Cirru, other : Cirru) -> Int {
  match (self, other) {
    (Cirru::Leaf(a), Cirru::Leaf(b)) => a.compare(b)
    (Cirru::List(xs), Cirru::List(ys)) => {
      let size = @math.minimum(xs.length(), ys.length())
      for i = 0; i < size; i = i + 1 {
        let x = xs[i]
        let y = ys[i]
        let c = x.compare(y)
        if c != 0 {
          return c
        }
      }
      return xs.length().compare(ys.length())
    }
    (Cirru::Leaf(_), Cirru::List(_)) => -1
    (Cirru::List(_), Cirru::Leaf(_)) => 1
  }
}

///|
pub fn length(self : Cirru) -> Int {
  match self {
    Leaf(s) => s.length()
    List(xs) => xs.length()
  }
}

///|
pub fn is_empty(self : Cirru) -> Bool {
  match self {
    Leaf(s) => s.length() == 0
    List(xs) => xs.length() == 0
  }
}

///|
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

///|
pub fn is_comment(self : Cirru) -> Bool {
  match self {
    Leaf(s) => s[0] == ';'
    _ => false
  }
}

///|
priv enum CirruLexState {
  Space
  Token
  Escape
  Indent
  Str
} derive(Show)

///|
priv enum CirruLexItem {
  Open
  Close
  Indent(Int)
  Str(String)
}

///|
impl Show for CirruLexItem with output(self : CirruLexItem, logger : &Logger) -> Unit {
  logger.write_string(self.to_string())
}

///|
fn CirruLexItem::to_string(self : CirruLexItem) -> String {
  match self {
    CirruLexItem::Open => "("
    CirruLexItem::Close => ")"
    CirruLexItem::Indent(size) => "indent(\{size})"
    CirruLexItem::Str(s) => s
  }
}

///|
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

///|
fn escape_cirru_leaf(s : String) -> String {
  if CirruLexItem::is_normal_str(s) {
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
