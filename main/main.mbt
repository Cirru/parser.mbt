fn main {
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

pub extern "js" fn fsReadSync(path : String) -> String =
  #|(path) => {
  #|  const fs = require("node:fs");
  #|  return fs.readFileSync(path, { encoding: "utf8" });
  #|}
