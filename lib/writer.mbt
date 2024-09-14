enum WriterNode {
  Nil
  Leaf
  SimpleExpr
  BoxedExpr
  Expr
} derive(Eq)

let char_close : Char = ')'

let char_open : Char = '('

let allowed_chars : String = "$-:<>[]{}*=+.,\\/!?~_@#&%^|;'"

fn is_a_digit(c : Char) -> Bool {
  let n = c.to_int()
  // ascii table https://tool.oschina.net/commons?type=4
  n >= 48 && n <= 57
}

fn is_a_letter(c : Char) -> Bool {
  let n = c.to_int()
  if n >= 65 && n <= 90 {
    return true
  }
  if n >= 97 && n <= 122 {
    return true
  }
  false
}

fn is_simple_expr(ys : Array[Cirru]) -> Bool {
  for y in ys {
    match y {
      Cirru::List(_) => return false
      Cirru::Leaf(_) => ()
    }
  }
  true
}

fn is_boxed(ys : Array[Cirru]) -> Bool {
  for y in ys {
    match y {
      Cirru::List(_) => return false
      Cirru::Leaf(_) => ()
    }
  }
  true
}

fn is_simple_char(x : Char) -> Bool {
  is_a_letter(x) || is_a_digit(x)
}

fn is_char_allowed(x : Char) -> Bool {
  if is_simple_char(x) {
    return true
  }
  allowed_chars.contains_char(x)
}

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
    ret = ret + "\""
    for c in s {
      ret = ret +
        (match c {
          '\n' => "\\n"
          '\t' => "\\t"
          '\"' => "\\\""
          '\\' => "\\\\"
          '\'' => "\\'"
          _ => "\{c}"
        })
    }
    ret = ret + "\""
    ret
  }
}

fn generate_empty_expr() -> String {
  "()"
}

fn generate_inline_expr(xs : Array[Cirru]) -> String {
  let mut result = char_open.to_string()
  for idx, x in xs {
    if idx > 0 {
      result = result + " "
    }
    let piece = match x {
      Cirru::Leaf(s) => generate_leaf(s)
      Cirru::List(ys) => generate_inline_expr(ys)
    }
    result = result + piece
  }
  result = result + char_close.to_string()
  result
}

/// by 2 spaces
fn push_spaces(buf : String, n : Int) -> String {
  let mut ret = buf
  // for _ in 0..n {
  //   buf.push_str("  ");
  // }
  for i = 0; i < n; i = i + 1 {
    ret = ret + "  "
  }
  return ret
}

fn render_newline(n : Int) -> String {
  let mut ret = ""
  ret = ret + "\n"
  ret = push_spaces(ret, n)
  ret
}

/// options for writer, `use_inline` for more compact format.
pub struct CirruWriterOptions {
  use_inline : Bool
}

fn get_node_kind(cursor : Cirru) -> WriterNode {
  match cursor {
    Cirru::Leaf(_) => WriterNode::Leaf
    Cirru::List(xs) =>
      if xs.is_empty() {
        WriterNode::Leaf
      } else if is_simple_expr(xs) {
        WriterNode::SimpleExpr
      } else if is_boxed(xs) {
        WriterNode::BoxedExpr
      } else {
        WriterNode::Expr
      }
  }
}

type! GenerateTreeError String

fn generate_tree(
  xs : Array[Cirru],
  insist_head : Bool,
  options : CirruWriterOptions,
  base_level : Int,
  in_tail : Bool
) -> String!GenerateTreeError {
  let mut prev_kind = WriterNode::Nil
  let mut level = base_level
  let mut result = ""
  for idx, cursor in xs {
    let kind = get_node_kind(cursor)
    let next_level = level + 1
    let child_insist_head = prev_kind == WriterNode::BoxedExpr ||
      prev_kind == WriterNode::Expr
    let at_tail = idx != 0 &&
      not(in_tail) &&
      prev_kind == WriterNode::Leaf &&
      idx == xs.length() - 1

    // println!("\nloop {:?} {:?}", prev_kind, kind);
    // println!("cursor {:?} {} {}", cursor, idx, insist_head);
    // println!("{:?}", result);

    let child : String = match cursor {
      Cirru::Leaf(s) => generate_leaf(s)
      Cirru::List(ys) =>
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
        } else if kind == WriterNode::Leaf {
          if idx == 0 {
            let mut ret = render_newline(level)
            ret = ret + generate_empty_expr()
            ret
          } else {
            generate_empty_expr() // special since empty expr is treated as leaf
          }
        } else if kind == WriterNode::SimpleExpr {
          if prev_kind == WriterNode::Leaf {
            generate_inline_expr(ys)
          } else if options.use_inline && prev_kind == WriterNode::SimpleExpr {
            let mut ret = " "
            ret = ret + generate_inline_expr(ys)
            ret
          } else {
            let mut ret = render_newline(next_level)
            ret = ret +
              generate_tree!(ys, child_insist_head, options, next_level, false)
            ret
          }
        } else if kind == WriterNode::Expr {
          let content = generate_tree!(
            ys, child_insist_head, options, next_level, false,
          )
          if content.starts_with("\n") {
            content
          } else {
            let mut ret = render_newline(next_level)
            ret = ret + content
            ret
          }
        } else if kind == WriterNode::BoxedExpr {
          let content = generate_tree!(
            ys, child_insist_head, options, next_level, false,
          )
          if prev_kind == WriterNode::Nil ||
            prev_kind == WriterNode::Leaf ||
            prev_kind == WriterNode::SimpleExpr {
            content
          } else {
            let mut ret = render_newline(next_level)
            ret = ret + content
            ret
          }
        } else {
          raise GenerateTreeError("Unpected condition")
        }
    }
    let bended = kind == WriterNode::Leaf &&
      (prev_kind == WriterNode::BoxedExpr || prev_kind == WriterNode::Expr)
    let chunk = if at_tail ||
      (prev_kind == WriterNode::Leaf && kind == WriterNode::Leaf) ||
      (prev_kind == WriterNode::Leaf && kind == WriterNode::SimpleExpr) ||
      (prev_kind == WriterNode::SimpleExpr && kind == WriterNode::Leaf) {
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

    if kind == WriterNode::SimpleExpr {
      if idx == 0 && insist_head {
        prev_kind = WriterNode::SimpleExpr
      } else if options.use_inline {
        if prev_kind == WriterNode::Leaf || prev_kind == WriterNode::SimpleExpr {
          prev_kind = WriterNode::SimpleExpr
        } else {
          prev_kind = WriterNode::Expr
        }
      } else if prev_kind == WriterNode::Leaf {
        prev_kind = WriterNode::SimpleExpr
      } else {
        prev_kind = WriterNode::Expr
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

fn generate_statements(
  ys : Array[Cirru],
  options : CirruWriterOptions
) -> String!GenerateTreeError {
  let mut zs = ""
  for y in ys {
    match y {
      Cirru::Leaf(_) =>
        raise GenerateTreeError("expected an exprs at top level")
      Cirru::List(cs) => {
        zs = zs + "\n"
        zs = zs + generate_tree!(cs, true, options, 0, false)
        zs = zs + "\n"
      }
    }
  }
  zs
}

/// format Cirru code, use options to control `use_inline` option
pub fn format(
  xs : Array[Cirru],
  options : CirruWriterOptions
) -> String!GenerateTreeError {
  generate_statements!(xs, options)
}
