import gleam/bool
import gleam/dynamic

import gleam/list
import gleam/string
import lustre
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

type Msg {
  UserRequestsJson
  ApiReturnedJson(Result(JsonCategories, lustre_http.HttpError))
}

fn update(model: Model, msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    ApiReturnedJson(Ok(json)) -> {
      #(Model(..model, json_loaded: True, json_content: json), effect.none())
    }
    ApiReturnedJson(Error(_)) -> #(
      Model(..model, json_loaded: False),
      effect.none(),
    )

    UserRequestsJson -> #(
      Model(..model, json_requested: True),
      get_json_from_api(),
    )
  }
}

fn render_jeopardy_grid(model: Model) {
  case model.json_loaded {
    True -> div([], [text("sometext")])
    _ -> div([], [text("nothing to render")])
  }
}

type Model {
  Model(json_loaded: Bool, json_requested: Bool, json_content: JsonCategories)
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    Model(
      json_loaded: False,
      json_requested: False,
      json_content: JsonCategories([]),
    ),
    effect.none(),
  )
}

fn view(model: Model) {
  let loaded = bool.to_string(model.json_loaded)
  let requested = bool.to_string(model.json_requested)
  div([], [
    text("Loaded " <> loaded <> " "),
    text("Requested " <> requested <> " "),
    button([event.on_click(UserRequestsJson)], [element.text("Call Json")]),
    render_jeopardy_grid(model),
  ])
}

// Main function to render the app
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)
  Nil
}
