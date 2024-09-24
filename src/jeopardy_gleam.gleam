import gleam/dynamic
import gleam/int
import gleam/json
import gleam/list
import gleam/result
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
  "\"categories\": [
    {
      \"category\": \"Science\",
      \"answers\": [
        {
          \"question\": \"What is the boiling point of water?\",
          \"answer\": \"100°C\"
        }
        ]
      }
    ]"
}

pub type JsonCategories {
  JsonCategories(categories: List(JsonCategory))
}

pub type JsonCategory {
  JsonCategory(category: String)
}

fn extract_categories(json_string: String) -> String {
  // Define a decoder for the "category" field inside each object in the "categories" array
  let category_decoder =
    dynamic.decode1(JsonCategory, dynamic.field("category", dynamic.string))

  // Define a decoder for the "categories" array wrapped in the JsonCategories type
  let categories_decoder =
    dynamic.decode1(
      JsonCategories,
      dynamic.field("categories", dynamic.list(category_decoder)),
    )

  let decoded = json.decode(json_string, categories_decoder)

  // Extract the first category or return the fallback string
  case decoded {
    Ok(JsonCategories([JsonCategory(category)])) -> category
    Error(error) -> decode_error_to_string(error)
    _ -> "json decode failed"
    // Fallback if decoding fails
  }
}

fn decode_error_to_string(error: json.DecodeError) -> String {
  case error {
    json.UnexpectedEndOfInput -> "Unexpected end of input"
    json.UnexpectedByte(message, second) ->
      "Unexpected byte: " <> message <> second
    json.UnexpectedSequence(message, _) -> "Unexpected sequence: " <> message
    _ -> "dont know"
  }
}
