import gleam/io

pub type Cardinal {
  North()
  East()
  South()
  West()
}

pub fn print_cardinal(cardinal: Cardinal) {
  case cardinal {
    North() -> io.println("North")
    East() -> io.println("East")
    South() -> io.println("South")
    West() -> io.println("West")
  }
}
