import gleam/int
import gleam/io
import gleam/list
import helper.{error_to_string}
import json_decoders.{type JsonCategories, type SingleCategory}
import lustre
import lustre/attribute.{class}
import lustre/effect
import lustre/element.{text}
import lustre/element/html.{button, div}
import lustre_http

fn view_th(lists: List(SingleCategory)) -> List(element.Element(a)) {
  list.map(lists, fn(single) {
    html.th([class("px-6 py-3")], [text(single.name)])
  })
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

fn view_td_by_points(
  points: Int,
  categories: List(SingleCategory),
) -> List(element.Element(a)) {
  list.map(filter_answers_by_points(categories, points), fn(answer) {
    html.td([class("px-6 py-4 hover:bg-blue-500")], [
      text(int.to_string(answer.points)),
    ])
  })
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
  let style_tr = "bg-blue-400 border-b"
  case model.json_loaded {
    True ->
      html.div([class("relative overflow-x-auto sm:rounded-lg bg-blue-200")], [
        html.table(
          [class("w-full text-sm text-center border-spacing-1 border-separate")],
          [
            html.thead([class("text-xs text-gray-700 uppercase bg-blue-700")], [
              html.tr(
                [
                  class(
                    "w-full text-sm text-center text-gray-500 dark:text-gray-400",
                  ),
                ],
                view_th(model.json_content.categories),
              ),
            ]),
            html.tr(
              [class(style_tr)],
              view_td_by_points(100, model.json_content.categories),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(200, model.json_content.categories),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(300, model.json_content.categories),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(400, model.json_content.categories),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(500, model.json_content.categories),
            ),
          ],
        ),
      ])
    _ -> div([], [text("Something went wrong in parsing JSON, or API calling")])
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
    get_json_from_api(),
  )
}

fn view(model: Model) {
  div([class("container mx-auto")], [
    div([class("relative py-15")], [view_render_jeopardy_grid(model)]),
  ])
}

// Main function to render the app
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
