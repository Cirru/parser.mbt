pub fn demo_parser() -> Unit {
  match @lib.parse("DEMO") {
    Ok(tree) => debug(tree)
    Err(err) => debug(err)
  }
}
