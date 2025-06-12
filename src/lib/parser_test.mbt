///|
typealias @lib.Cirru

///|
test "parser" {
  assert_eq(Cirru::parse("def a"), [List([Leaf("def"), Leaf("a")])])
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
    let tree = Cirru::parse?(demo_file).unwrap().to_json().stringify()
    let defined = @json.parse?(json_file).unwrap()
    let defined_str = defined.stringify()
    assert_eq(tree, defined_str)
    let formatted = Cirru::format(@json.from_json(defined), {
      use_inline: false,
    })
    let ret = Cirru::parse?(formatted).unwrap().to_json().stringify()
    assert_eq(ret, defined_str)
  }
}

///|
pub extern "js" fn fsReadSync(path : String) -> String =
  #|(path) => {
  #|  const fs = require("node:fs");
  #|  return fs.readFileSync(path, { encoding: "utf8" });
  #|}
