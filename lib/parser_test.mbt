test "parser" {
  if parse("demo") != Ok(Cirru::Leaf("TODO...")) {
    abort("parsed wrong!")
  }
}
