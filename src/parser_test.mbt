///|
using @lib {type Cirru}

///|
test "parser" {
  assert_eq(Cirru::parse("def a"), [
    Cirru::List([Cirru::Leaf("def"), Cirru::Leaf("a")]),
  ])
}

///|
test "parse and format one-liner expression" {
  let tree = Cirru::List([
    Cirru::Leaf("defn"),
    Cirru::Leaf("main"),
    Cirru::List([]),
    Cirru::List([Cirru::Leaf("println"), Cirru::Leaf("Hello, world!")]),
  ])

  let one_liner = try! tree.format_one_liner()
  assert_eq(one_liner, "defn main () $ println \"Hello, world!\"")

  let parsed = try! Cirru::parse_expr_one_liner(one_liner)
  assert_eq(parsed, tree)
}

///|
test "reject multiple expressions in one-liner parser" {
  let result = try? Cirru::parse_expr_one_liner("a\nb")
  match result {
    Err(err) => assert_eq(err.to_string(), "expected 1 expression, got 2")
    Ok(_) => assert_eq("ok", "err")
  }
}

///|
test "format complex one-liner expression" {
  let tree = Cirru::List([
    Cirru::Leaf("a"),
    Cirru::List([Cirru::Leaf("b"), Cirru::List([Cirru::Leaf("c")])]),
    Cirru::Leaf("d"),
  ])

  let one_liner = try! tree.format_one_liner()
  assert_eq(one_liner, "a (b (c)) d")

  let parsed = try! Cirru::parse_expr_one_liner(one_liner)
  assert_eq(parsed, tree)
}

///|
test "format tail expression one-liner" {
  let tree = Cirru::List([
    Cirru::Leaf("defn"),
    Cirru::Leaf("main"),
    Cirru::List([]),
    Cirru::List([Cirru::Leaf("println"), Cirru::Leaf("Hello")]),
  ])

  let one_liner = try! tree.format_one_liner()
  assert_eq(one_liner, "defn main () $ println Hello")

  let parsed = try! Cirru::parse_expr_one_liner(one_liner)
  assert_eq(parsed, tree)
}

///|
test "format nested tail expression one-liner" {
  let tree = Cirru::List([
    Cirru::Leaf("if"),
    Cirru::Leaf("condition"),
    Cirru::List([Cirru::Leaf("do"), Cirru::List([Cirru::Leaf("action")])]),
  ])

  let one_liner = try! tree.format_one_liner()
  assert_eq(one_liner, "if condition $ do $ action")

  let parsed = try! Cirru::parse_expr_one_liner(one_liner)
  assert_eq(parsed, tree)
}

///|
test "format empty tail expression one-liner" {
  let tree = Cirru::List([Cirru::Leaf("a"), Cirru::Leaf("b"), Cirru::List([])])

  let one_liner = try! tree.format_one_liner()
  assert_eq(one_liner, "a b $")

  let parsed = try! Cirru::parse_expr_one_liner(one_liner)
  assert_eq(parsed, tree)
}

///|
test "existed demos" {
  let demos = [
    "comma", "demo", "folding", "html", "indent-twice", "indent", "let", "line",
    "list-match", "paren-indent", "paren-indent2", "parentheses", "quote", "spaces",
    "unfolding",
  ]
  for demo in demos {
    let demo_file = fsReadSync("./test/cirru/\{demo}.cirru")
    let json_file = fsReadSync("./test/data/\{demo}.json")
    let tree = (try! Cirru::parse(demo_file)).to_json().stringify()
    let defined = try! @json.parse(json_file)
    let defined_str = defined.stringify()
    assert_eq(tree, defined_str)
    let formatted = Cirru::format(@json.from_json(defined), use_inline=false)
    let ret = (try! Cirru::parse(formatted)).to_json().stringify()
    assert_eq(ret, defined_str)
  }
}

///|
pub extern "js" fn fsReadSync(path : String) -> String =
  #|(path) => {
  #|  const fs = require("node:fs");
  #|  return fs.readFileSync(path, { encoding: "utf8" });
  #|}
