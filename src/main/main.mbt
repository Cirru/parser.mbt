///|
pub fn main_parser() -> Unit {
  // let tree = @lib.parse?("DEMO")
  // match tree {
  //   Result::Ok(tree) => {
  //   println(tree.to_json().stringify())
  //   println(tree)}
  //   Result::Err(err) => println(err.to_string())
  // }

  let demo_file = fsReadSync("./test/cirru/unfolding.cirru")
  let json_file = fsReadSync("./test/data/unfolding.json")
  let tree = @lib.parse?(demo_file)
  match tree {
    Result::Ok(tree) => {
      println(tree.to_json().stringify())
      match @json.parse?(json_file) {
        Result::Ok(json) => println(json.stringify())
        Result::Err(err) => println(err.to_string())
      }
      // println(tree)
    }
    Result::Err(err) => println(err.to_string())
  }
}

///|
pub fn main_writer() -> Unit {
  let demo = "unfolding"
  let demo_file = fsReadSync("./test/cirru/\{demo}.cirru")
  let json_file = fsReadSync("./test/data/\{demo}.json")
  let defined = @json.parse?(json_file).unwrap()
  let tree : Array[@lib.Cirru] = @json.from_json?(defined).unwrap()
  println("TREE:")
  for item in tree {
    println(item.to_json().stringify())
  }
  let ret = @lib.format?(tree, { use_inline: false }).unwrap()
  println("Generated:")
  println(ret)
  println("Expected:")
  println(demo_file)
  println("")
}

///|
fn main {
  main_parser()
}

///|
pub extern "js" fn fsReadSync(path : String) -> String =
  #|(path) => {
  #|  const fs = require("node:fs");
  #|  return fs.readFileSync(path, { encoding: "utf8" });
  #|}
