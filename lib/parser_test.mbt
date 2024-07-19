test "parser" {
  if @lib.parse("demo文字demo") != Ok(@lib.Cirru::Leaf("TODO...")) {
    abort("parsed wrong!")
  }
}
