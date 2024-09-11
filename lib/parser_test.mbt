test "parser" {
  println(@lib.parse!("def a"))
  assert_eq!(
    @lib.parse!("def a"),
    [@lib.Cirru::Leaf("def"), @lib.Cirru::Leaf("a")],
  )
}
