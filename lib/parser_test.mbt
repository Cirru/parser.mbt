test "parser" {
  if @lib.parse!("def a") != [@lib.Cirru::Leaf("def"), @lib.Cirru::Leaf("a")] {
    abort("parsed wrong!")
  }
}
