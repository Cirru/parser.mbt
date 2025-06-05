///|
fn resolve_comma(xs : Array[Cirru]) -> Array[Cirru] {
  if xs.is_empty() {
    []
  } else {
    comma_helper(xs)
  }
}

///|
fn comma_helper(initial_after : Array[Cirru]) -> Array[Cirru] {
  let before : Array[Cirru] = []
  let after : Array[Cirru] = initial_after
  let mut pointer = 0
  for {
    if pointer >= after.length() {
      return before
    }
    match after[pointer] {
      List(xs) =>
        if not(xs.is_empty()) {
          match xs[0] {
            List(_) => before.push(List(resolve_comma(xs)))
            Leaf(s) =>
              if s == "," {
                before.push_iter(resolve_comma(xs[1:].iter().to_array()).iter())
              } else {
                before.push(List(resolve_comma(xs)))
              }
          }
        } else {
          before.push(List([]))
        }
      Leaf(_) => before.push(after[pointer])
    }
    pointer += 1
  }
}

///|
fn resolve_dollar(xs : Array[Cirru]) -> Array[Cirru] {
  if xs.is_empty() {
    []
  } else {
    dollar_helper(xs)
  }
}

///|
fn dollar_helper(initial_after : Array[Cirru]) -> Array[Cirru] {
  let before : Array[Cirru] = []
  let after : Array[Cirru] = initial_after
  let mut pointer = 0
  for {
    if pointer >= after.length() {
      return before
    } else {
      match after[pointer] {
        List(xs) => {
          before.push(List(resolve_dollar(xs)))
          pointer += 1
        }
        Leaf(s) =>
          if s == "$" {
            before.push(
              List(resolve_dollar(after[pointer + 1:].iter().to_array())),
            )
            pointer = after.length()
          } else {
            before.push(Leaf(s))
            pointer += 1
          }
      }
    }
  }
}
