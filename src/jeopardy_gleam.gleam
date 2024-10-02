import gleam/dynamic
import gleam/json
import gleam/list
import gleam/string
import lustre
import lustre/effect
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

// Lets try to add a simple model with msg
type Msg {
  Incr
}

fn update(model, msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    Incr -> #(Model(..model, count: model.count + 1), effect.none())
  }
}

type Model {
  Model(count: Int)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(Model(0), effect.none())
}

fn view(model) {
  div([], [text(extract_categories(get_json()))])
}

// Main function to render the app
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
