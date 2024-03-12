
enum Cirru {
  Leaf(String)
  List(Array[Cirru])
} derive(Debug)

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

enum CirruLexItem {
  Open
  Close
  Indent(Int)
  Str(String)
}

fn is_normal_str(tok: String) -> Bool {
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

pub fn parse(content: String) -> Result[Cirru, String] {
  Ok(Cirru::Leaf("TODO"))
}
