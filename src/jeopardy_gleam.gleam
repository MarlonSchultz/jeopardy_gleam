import gleam/bool
import gleam/dynamic
import gleam/int
import gleam/io
import gleam/json
import gleam/list
import gleam/string
import lustre
import lustre/attribute
import lustre/effect
import lustre/element.{text}
import lustre/element/html.{button, div}
import lustre/event
import lustre_http

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

fn get_json_from_api() -> effect.Effect(Msg) {
  let expect =
    lustre_http.expect_json(decode_json_categories(), ApiReturnedJson)
  lustre_http.get("http://localhost:8080/answers.json", expect)
}

fn json_string() -> String {
  "{
    \"categories\": [
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

type Msg {
  UserRequestsJson
  ApiReturnedJson(Result(JsonCategories, lustre_http.HttpError))
}

fn update(model: Model, msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    ApiReturnedJson(Ok(_json)) -> #(
      Model(..model, json_loaded: True),
      effect.none(),
    )
    ApiReturnedJson(Error(error)) -> #(
      Model(..model, json_loaded: False, json_string: error_to_string(error)),
      effect.none(),
    )

    UserRequestsJson -> #(
      Model(..model, json_requested: True),
      get_json_from_api(),
    )
  }
}

fn error_to_string(error: lustre_http.HttpError) -> String {
  case error {
    lustre_http.BadUrl(url) -> "Invalid URL: " <> url
    lustre_http.InternalServerError(body) ->
      "Server returned 500 Internal Server Error: " <> body
    lustre_http.JsonError(_) -> "Error decoding the JSON response"
    lustre_http.NetworkError -> "Network error occurred"
    lustre_http.NotFound -> "The server returned 404 Not Found"
    lustre_http.OtherError(code, body) ->
      "HTTP Error " <> int.to_string(code) <> ": " <> body
    lustre_http.Unauthorized -> "The server returned 401 Unauthorized"
  }
}

type Model {
  Model(json_loaded: Bool, json_requested: Bool, json_string: String)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(json_loaded: False, json_requested: False, json_string: ""),
    effect.none(),
  )
}

fn view(model: Model) {
  let loaded = bool.to_string(model.json_loaded)
  let requested = bool.to_string(model.json_requested)
  div([], [
    text("Loaded " <> loaded <> " "),
    text("Requested " <> requested <> " "),
    text("Content" <> model.json_string <> " "),
    text("Json Local parse" <> extract_categories(json_string()) <> " "),
    button([event.on_click(UserRequestsJson)], [element.text("Call Json")]),
  ])
}

// Main function to render the app
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
