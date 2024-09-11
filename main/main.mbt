fn main {
  let tree = @lib.parse?("DEMO")
  match tree {
    Result::Ok(tree) => println(tree)
    Result::Err(err) => println(err.to_string())
  }
  println("done")
}
