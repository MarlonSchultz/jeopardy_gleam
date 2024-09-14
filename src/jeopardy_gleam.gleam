import lustre
import lustre/element

pub fn main() {
  let app = lustre.element(element.text("Hello, world!"))
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
