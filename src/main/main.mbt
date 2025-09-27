///|
typealias @lib.Cirru

///|
pub fn main_parser() -> Unit {
  // let tree = @lib.parse?("DEMO")
  // match tree {
  //   Ok(tree) => {
  //   println(tree.to_json().stringify())
  //   println(tree)}
  //   Err(err) => println(err.to_string())
  // }

  let demo_file = fsReadSync("./test/cirru/unfolding.cirru")
  let json_file = fsReadSync("./test/data/unfolding.json")
  let tree = try? Cirru::parse(demo_file)
  match tree {
    Ok(tree) => {
      println(tree.to_json().stringify())
      match (try? @json.parse(json_file)) {
        Ok(json) => println(json.stringify())
        Err(err) => println(err.to_string())
      }
      // println(tree)
    }
    Err(err) => println(err.to_string())
  }
}

///|
pub fn main_writer() -> Unit {
  let demo = "unfolding"
  let demo_file = fsReadSync("./test/cirru/\{demo}.cirru")
  let json_file = fsReadSync("./test/data/\{demo}.json")
  let defined = (try? @json.parse(json_file)).unwrap()
  let tree : Array[Cirru] = (try? @json.from_json(defined)).unwrap()
  println("TREE:")
  for item in tree {
    println(item.to_json().stringify())
  }
  let ret = (try? Cirru::format(tree, { use_inline: false })).unwrap()
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
