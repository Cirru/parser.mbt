///|
priv enum WriterNode {
  /// Nil node, which is used to indicate no previous node
  Nil
  /// Leaf node, which is a string
  Leaf
  /// SimpleExpr node, which is a simple expression with no nested lists
  SimpleExpr
  /// Simple expression, which is a list with no nested lists
  BoxedExpr
  /// Expr node, which can be complex
  Expr
} derive(Eq)

///| `)`, end of a list
let char_close : Char = ')'

///| `(`, start of a list)
let char_open : Char = '('

///| Allowed characters in a leaf node, which can be used to generate a string safely
let allowed_chars : String = "$-:<>[]{}*=+.,\\/!?~_@#&%^|;'"

///|
fn is_a_digit(c : Char) -> Bool {
  let n = c.to_int()
  // ascii table https://tool.oschina.net/commons?type=4
  n >= 48 && n <= 57
}

///|
fn is_a_letter(c : Char) -> Bool {
  match c {
    'A'..='Z' => true
    'a'..='z' => true
    _ => false
  }
}

///| Check if the expression is simple, which means it has no nested lists
fn is_simple_expr(ys : Array[Cirru]) -> Bool {
  for y in ys {
    match y {
      List(_) => return false
      Leaf(_) => ()
    }
  }
  true
}

///| Check if the expression is boxed, which means it has no nested lists
fn is_boxed(ys : Array[Cirru]) -> Bool {
  for y in ys {
    match y {
      Leaf(_) => return false
      List(_) => ()
    }
  }
  true
}

///| Check if the character is a simple character, which means it is a letter or a digit
fn is_simple_char(x : Char) -> Bool {
  is_a_letter(x) || is_a_digit(x)
}

///|
fn is_char_allowed(x : Char) -> Bool {
  if is_simple_char(x) {
    return true
  }
  allowed_chars.contains_char(x)
}

///| Generate a leaf node, which is a string that may contain special characters
fn generate_leaf(s : String) -> String {
  let mut all_allowed = true
  for x in s {
    if not(is_char_allowed(x)) {
      all_allowed = false
      break
    }
  }
  if all_allowed {
    s.to_string()
  } else {
    let mut ret = ""
    ret += "\""
    for c in s {
      let content = match c {
        '\n' => "\\n"
        '\t' => "\\t"
        '\"' => "\\\""
        '\\' => "\\\\"
        '\'' => "\\'"
        _ => "\{c}"
      }
      ret += content
    }
    ret += "\""
    ret
  }
}

///|
fn generate_empty_expr() -> String {
  "()"
}

///|
fn generate_inline_expr(xs : Array[Cirru]) -> String {
  let mut result = char_open.to_string()
  for idx, x in xs {
    if idx > 0 {
      result += " "
    }
    let piece = match x {
      Leaf(s) => generate_leaf(s)
      List(ys) => generate_inline_expr(ys)
    }
    result += piece
  }
  result += char_close.to_string()
  result
}

///| by 2 spaces
fn push_spaces(buf : String, n : Int) -> String {
  let mut ret = buf
  for i = 0; i < n; i = i + 1 {
    ret += "  "
  }
  return ret
}

///|
fn render_newline(n : Int) -> String {
  let mut ret = ""
  ret += "\n"
  ret = push_spaces(ret, n)
  ret
}

///| options for writer, `use_inline` for more compact format.
pub(all) struct CirruWriterOptions {
  use_inline : Bool
}

///| kind for writer nodes
fn Cirru::get_node_kind(self : Cirru) -> WriterNode {
  match self {
    Leaf(_) => Leaf
    List(xs) =>
      if xs.is_empty() {
        Leaf
      } else if is_simple_expr(xs) {
        SimpleExpr
      } else if is_boxed(xs) {
        BoxedExpr
      } else {
        Expr
      }
  }
}

///|
pub(all) type! FormatCirruError String derive(Show)

///|
fn generate_tree(
  xs : Array[Cirru],
  insist_head : Bool,
  options : CirruWriterOptions,
  base_level : Int,
  in_tail : Bool
) -> String!FormatCirruError {
  let mut prev_kind : WriterNode = Nil
  let mut level = base_level
  let mut result = ""
  for idx, cursor in xs {
    let kind = cursor.get_node_kind()
    let next_level = level + 1
    let child_insist_head = prev_kind == BoxedExpr || prev_kind == Expr
    let at_tail = idx != 0 &&
      not(in_tail) &&
      prev_kind == Leaf &&
      idx == xs.length() - 1

    // println!("\nloop {:?} {:?}", prev_kind, kind);
    // println!("cursor {:?} {} {}", cursor, idx, insist_head);
    // println!("{:?}", result);

    let child : String = match cursor {
      Leaf(s) => generate_leaf(s)
      List(ys) =>
        if at_tail {
          if ys.is_empty() {
            "$"
          } else {
            let mut ret = "$ "
            ret = ret + generate_tree!(ys, false, options, level, at_tail)
            ret
          }
        } else if idx == 0 && insist_head {
          generate_inline_expr(ys)
        } else if kind == Leaf {
          if idx == 0 {
            let mut ret = render_newline(level)
            ret = ret + generate_empty_expr()
            ret
          } else {
            generate_empty_expr() // special since empty expr is treated as leaf
          }
        } else if kind == SimpleExpr {
          if prev_kind == Leaf {
            generate_inline_expr(ys)
          } else if options.use_inline && prev_kind == SimpleExpr {
            let mut ret = " "
            ret = ret + generate_inline_expr(ys)
            ret
          } else {
            let mut ret = render_newline(next_level)
            ret = ret +
              generate_tree!(ys, child_insist_head, options, next_level, false)
            ret
          }
        } else if kind == Expr {
          let content = generate_tree!(
            ys, child_insist_head, options, next_level, false,
          )
          if content.has_prefix("\n") {
            content
          } else {
            let mut ret = render_newline(next_level)
            ret = ret + content
            ret
          }
        } else if kind == BoxedExpr {
          let content = generate_tree!(
            ys, child_insist_head, options, next_level, false,
          )
          if prev_kind == Nil || prev_kind == Leaf || prev_kind == SimpleExpr {
            content
          } else {
            let mut ret = render_newline(next_level)
            ret = ret + content
            ret
          }
        } else {
          raise FormatCirruError("Unpected condition")
        }
    }
    let bended = kind == Leaf && (prev_kind == BoxedExpr || prev_kind == Expr)
    let chunk = if at_tail ||
      (prev_kind == Leaf && kind == Leaf) ||
      (prev_kind == Leaf && kind == SimpleExpr) ||
      (prev_kind == SimpleExpr && kind == Leaf) {
      let mut ret = " "
      ret = ret + child
      ret
    } else if bended {
      let mut ret = render_newline(next_level)
      ret = ret + ", " + child
      ret
    } else {
      child
    }
    result = result + chunk

    // update writer states

    if kind == SimpleExpr {
      if idx == 0 && insist_head {
        prev_kind = SimpleExpr
      } else if options.use_inline {
        if prev_kind == Leaf || prev_kind == SimpleExpr {
          prev_kind = SimpleExpr
        } else {
          prev_kind = Expr
        }
      } else if prev_kind == Leaf {
        prev_kind = SimpleExpr
      } else {
        prev_kind = Expr
      }
    } else {
      prev_kind = kind
    }
    if bended {
      level += 1
    }
  }

  // console.log("chunk", JSON.stringify(chunk));
  // console.log("And result", JSON.stringify(result));
  result
}

///|
fn generate_statements(
  ys : Array[Cirru],
  options : CirruWriterOptions
) -> String!FormatCirruError {
  let mut zs = ""
  for y in ys {
    match y {
      Leaf(_) => raise FormatCirruError("expected an exprs at top level")
      List(cs) => {
        zs += "\n"
        zs += generate_tree!(cs, true, options, 0, false)
        zs += "\n"
      }
    }
  }
  zs
}

///| format Cirru code, use options to control `use_inline` option
pub fn Cirru::format(
  xs : Array[Cirru],
  options : CirruWriterOptions
) -> String!FormatCirruError {
  generate_statements!(xs, options)
}
