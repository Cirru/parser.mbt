test "parser" {
  if parse("demo文字demo") != Ok(Cirru::Leaf("TODO...")) {
    abort("parsed wrong!")
  }
}
