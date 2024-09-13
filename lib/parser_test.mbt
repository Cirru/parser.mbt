test "parser" {
  assert_eq!(
    @lib.parse!("def a"),
    [@lib.Cirru::List([@lib.Cirru::Leaf("def"), @lib.Cirru::Leaf("a")])],
  )
}

test "existed demos" {
  let demos = [
    "comma", "demo", "folding", "html", "indent-twice", "indent", "let", "line",
    "list-match", "paren-indent", "paren-indent2", "parentheses", "quote", "spaces",
    "unfolding",
  ]
  for demo in demos {
    let demo_file = fsReadSync("./test/cirru/\{demo}.cirru")
    let json_file = fsReadSync("./test/data/\{demo}.json")
    let tree = @lib.parse?(demo_file).unwrap().to_json().stringify()
    let defined = @json.parse?(json_file).unwrap().stringify()
    assert_eq!(tree, defined)
  }
}

pub extern "js" fn fsReadSync(path : String) -> String =
  #|(path) => {
  #|  const fs = require("node:fs");
  #|  return fs.readFileSync(path, { encoding: "utf8" });
  #|}
