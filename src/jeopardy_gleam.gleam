import gleam/dynamic
import gleam/json
import gleam/list
import gleam/string
import lustre
import lustre/element.{text}
import lustre/element/html.{div}

// Type for a single category
pub type SingleCategory {
  SingleCategory(name: String)
}

pub fn decode_single_category() -> fn(dynamic.Dynamic) ->
  Result(SingleCategory, List(dynamic.DecodeError)) {
  dynamic.decode1(
    SingleCategory,
    dynamic.field("category", dynamic.field("name", dynamic.string)),
  )
}

// Type for the JSON categories
pub type JsonCategories {
  JsonCategories(categories: List(SingleCategory))
}

pub fn decode_json_categories() -> fn(dynamic.Dynamic) ->
  Result(JsonCategories, List(dynamic.DecodeError)) {
  dynamic.decode1(
    JsonCategories,
    dynamic.field("categories", dynamic.list(decode_single_category())),
  )
}

// Function to extract categories and display them
fn extract_categories(json_string: String) -> String {
  let decoded = json.decode(json_string, decode_json_categories())

  case decoded {
    Ok(JsonCategories(categories)) -> turn_json_list_into_string(categories)
    Error(_) -> "Error decoding JSON"
  }
}

// Convert the list of categories to a comma-separated string
fn turn_json_list_into_string(lists: List(SingleCategory)) -> String {
  let listed = list.map(lists, fn(single) { single.name })
  string.join(listed, ", ")
}

// Get the JSON string
fn get_json() -> String {
  "{\"categories\": [
    {
      \"category\": {
        \"name\": \"cat1\",
        \"answers\": [
          {
            \"answer\": \"AnswerString\",
            \"question\": \"QuestionString\",
            \"points\": 10
          }
        ]
      }
    }
  ]
  }"
}

// Main function to render the app
pub fn main() {
  let app = lustre.element(div([], [text(extract_categories(get_json()))]))
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
