pub fn demo_parser() -> Unit!@lib.CirruParseError {
  let tree = @lib.parse!("DEMO")
  println(tree)
}
