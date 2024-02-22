
enum Cirru {
  Leaf(String)
  List(Array[Cirru])
} derive(Debug)

fn op_equal(self: Cirru, other: Cirru) -> Bool {
  match self {
    Cirru::Leaf(a) => match other {
      Cirru::Leaf(b) => a == b
      _ => false
    }
    Cirru::List(xs) => match other {
      Cirru::List(ys) => {
        if xs.length() != ys.length() {
          return false
        }
        let size = xs.length()
        let mut i = 0
        while i <= size {
          if xs[i] != ys[i] {
            return false
          }
          i = i + 1
        }
        return true
      }
      _ => false
    }
  }
}

pub fn parse(content: String) -> Result[Cirru, String] {
  Ok(Cirru::Leaf("TODO"))
}
