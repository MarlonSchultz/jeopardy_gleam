import gleam/dynamic
import gleam/io
import gleam/json
import gleam/list
import gleam/string
import gleam/string_builder
import lustre
import lustre/element.{text}
import lustre/element/html.{button, div, p}
import lustre/event.{on_click}

pub fn main() {
  let app = lustre.element(html.div([], [text(extract_categories(get_json()))]))
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

fn get_json() -> String {
  "{\"categories\":  [
    {\"cat_name\": \"cat1\"},
    {\"cat_name\": \"cat2\"},
    {\"cat_name\": \"cat3\"}
  ]
  }"
}

pub type SingleCategory {
  SingleCategory(cat_name: String)
}

pub type JsonCategories {
  JsonCategories(categories: List(SingleCategory))
}

// Function to extract categories and display them
fn extract_categories(json_string: String) -> String {
  // Define a decoder for a single category object
  let single_category_decoder =
    dynamic.decode1(SingleCategory, dynamic.field("cat_name", dynamic.string))

  // Define a decoder for the list of categories
  let decoder =
    dynamic.decode1(
      JsonCategories,
      dynamic.field("categories", dynamic.list(single_category_decoder)),
    )

  // Decode the JSON string
  let decoded = json.decode(json_string, decoder)

  // Extract categories or return a fallback message
  case decoded {
    Ok(JsonCategories(categories)) -> turn_json_list_into_string(categories)
    Error(_) -> "Error decoding JSON"
  }
}

fn turn_json_list_into_string(lists: List(SingleCategory)) -> String {
  let listed = list.map(lists, fn(single) { single.cat_name })
  string.join(listed, ", ")
}
