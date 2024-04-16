pub fn demo_parser() -> Unit {
  match @cirru.parse("DEMO") {
    Ok(tree) => {
      debug(tree)
    }
    Err(err) => {
      debug(err)
    }
  }
}
