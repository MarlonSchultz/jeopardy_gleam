import gleam/bool
import gleam/io
import gleam/list
import helper.{error_to_string}
import json_decoders.{type JsonCategories, type SingleCategory}
import lustre
import lustre/effect
import lustre/element.{text}
import lustre/element/html.{button, div}
import lustre/event
import lustre_http

fn view_create_table_headers(
  lists: List(SingleCategory),
) -> List(element.Element(a)) {
  list.map(lists, fn(single) { html.th([], [text(single.name)]) })
}

fn filter_answers_by_points(
  categories: List(SingleCategory),
  target_points: Int,
) -> List(json_decoders.Answer) {
  categories
  |> list.map(fn(category) {
    category.answers
    |> list.filter(fn(answer) {
      case answer {
        json_decoders.Answer(_, _, points) if points == target_points -> True
        _ -> False
      }
    })
  })
  |> list.concat
}

fn get_json_from_api() -> effect.Effect(Msg) {
  let expect =
    lustre_http.expect_json(
      json_decoders.decode_json_categories(),
      ApiReturnedJson,
    )
  lustre_http.get("http://localhost:8080/answers.json", expect)
}

type Msg {
  UserRequestsJson
  ApiReturnedJson(Result(JsonCategories, lustre_http.HttpError))
}

fn update(model: Model, msg) -> #(Model, effect.Effect(Msg)) {
  case msg {
    ApiReturnedJson(Ok(json)) -> {
      io.debug(filter_answers_by_points(json.categories, 100))
      #(Model(..model, json_loaded: True, json_content: json), effect.none())
    }
    ApiReturnedJson(Error(error)) -> {
      error_to_string(error) |> io.debug
      #(Model(..model, json_loaded: False), effect.none())
    }

    UserRequestsJson -> #(
      Model(..model, json_requested: True),
      get_json_from_api(),
    )
  }
}

fn view_render_jeopardy_grid(model: Model) -> element.Element(a) {
  case model.json_loaded {
    True ->
      html.table([], [
        html.tr([], view_create_table_headers(model.json_content.categories)),
      ])
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
      json_content: json_decoders.JsonCategories([]),
    ),
    effect.none(),
  )
}

fn view(model: Model) {
  let loaded = bool.to_string(model.json_loaded)
  let requested = bool.to_string(model.json_requested)
  html.html([], [
    html.title([], "Jeopardy"),
    html.body([], [
      div([], [
        text("Loaded " <> loaded <> " "),
        text("Requested " <> requested <> " "),
        button([event.on_click(UserRequestsJson)], [element.text("Call Json")]),
        view_render_jeopardy_grid(model),
      ]),
    ]),
  ])
}

// Main function to render the app
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
