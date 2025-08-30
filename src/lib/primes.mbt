///|
/// Cirru uses nested Vecters and Strings as data structure
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
    Leaf(s) => i = s.length()
    List(xs) =>
      for _ in xs {
        i = i + 1 // TODO: how to hash a list?
      }
  }
  i
}

///|
pub impl Hash for Cirru with hash_combine(self, hasher) {
  match self {
    Leaf(s) => hasher.combine_string(s)
    List(xs) =>
      for x in xs {
        hasher.combine(x)
      }
  }
}

///|
pub impl ToJson for Cirru with to_json(self : Cirru) -> Json {
  match self {
    Leaf(s) => Json::string(s)
    List(xs) => {
      let out = Array::new()
      for x in xs {
        out.push(x.to_json())
      }
      Json::array(out)
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
        let v = @json.FromJson::from_json(x, path.add_index(idx))
        ys.push(v)
      }
      List(ys)
    }
    // _ => @json.decode_error!((path, "Char::from_json: expected string"))
    _ =>
      raise @json.JsonDecodeError(
        (path, "Cirru::from_json: expected string or array"),
      )
  }
}

///|
impl Default for Cirru with default() -> Cirru {
  List(Array::new())
}

///|
pub impl Show for Cirru with output(self : Cirru, logger : &Logger) -> Unit {
  match self {
    Leaf(s) =>
      if CirruLexItem::is_normal_str(s) {
        logger.write_string(s)
      } else {
        logger.write_string(escape_cirru_leaf(s))
      }
    List(xs) => {
      let mut out = ""
      for i = 0; i < xs.length(); i = i + 1 {
        let x = xs[i]
        out = "\{out}\{x}"
        if i < xs.length() - 1 {
          out = "\{out} "
        }
      }
      logger.write_string(out)
    }
  }
}

///|
pub impl Compare for Cirru with compare(self, other) -> Int {
  match (self, other) {
    (Leaf(a), Leaf(b)) => a.compare(b)
    (List(xs), List(ys)) => {
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
    (Leaf(_), List(_)) => -1
    (List(_), Leaf(_)) => 1
  }
}

///|
pub fn Cirru::length(self : Cirru) -> Int {
  match self {
    Leaf(s) => s.length()
    List(xs) => xs.length()
  }
}

///|
pub fn Cirru::is_empty(self : Cirru) -> Bool {
  match self {
    Leaf(s) => s.length() == 0
    List(xs) => xs.length() == 0
  }
}

///|
pub fn Cirru::is_nested(self : Cirru) -> Bool {
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
pub fn Cirru::is_comment(self : Cirru) -> Bool {
  match self {
    Leaf(s) => s.char_at(0) == ';'
    _ => false
  }
}

///|
/// lexer is a simpler state machine to tokenize Cirru code
priv enum CirruLexState {
  /// Space, waiting for next token
  Space
  /// Token, a normal token
  Token
  /// Escape, waiting for a character or some special sequence
  Escape
  /// Working on indentations
  Indent
  /// Working on a string
  Str
} derive(Show)

///|
/// lexer is a simpler state machine to tokenize Cirru code
priv enum CirruLexItem {
  /// `(`, start of a list
  Open
  /// `)`, end of a list
  Close
  /// Indentation level, used for nested lists
  Indent(Int)
  /// A string, which can be a normal string or a special one
  Str(String)
}

///|
impl Show for CirruLexItem with output(self : CirruLexItem, logger : &Logger) -> Unit {
  let content = match self {
    Open => "("
    Close => ")"
    Indent(size) => "indent(\{size})"
    Str(s) => s
  }
  logger.write_string(content)
}

///|
fn CirruLexItem::is_normal_str(tok : String) -> Bool {
  let size = tok.length()
  if size == 0 {
    return false
  }
  let mut i = 0
  while i < size {
    let c = tok.char_at(i)
    match c {
      'A'..='Z' => ()
      'a'..='z' => ()
      '0'..='9' => ()
      '-' => ()
      '?' => ()
      '!' => ()
      '+' => ()
      '*' => ()
      '$' => ()
      '@' => ()
      '#' => ()
      '%' => ()
      '&' => ()
      '_' => ()
      '=' => ()
      '|' => ()
      ':' => ()
      '.' => ()
      '<' => ()
      '>' => ()
      _ => return false
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
      let c = s.char_at(i)
      match c {
        '\n' => out += "\\n"
        '\t' => out += "\\t"
        '"' => out += "\\\""
        '\\' => out += "\\\\"
        '\'' => out += "\\'"
        _ => out += "\{c}"
      }
      i = i + 1
    }
    out += "\""
    return out
  }
}
