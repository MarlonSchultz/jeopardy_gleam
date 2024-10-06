import decoders/json_decoders.{type JsonCategories}
import lustre
import lustre/attribute.{class}
import lustre/effect
import lustre/element/html.{div, text}
import lustre_http
import model.{type Model, Model}
import views/jeopardy_grid/jeopardy_table.{view_jeopardy_table}

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
      #(Model(..model, json_loaded: True, json_content: json), effect.none())
    }
    ApiReturnedJson(Error(_error)) -> {
      #(Model(..model, json_loaded: False), effect.none())
    }

    UserRequestsJson -> #(
      Model(..model, json_requested: True),
      get_json_from_api(),
    )
  }
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    model.Model(
      json_loaded: False,
      json_requested: False,
      json_content: json_decoders.JsonCategories([]),
    ),
    get_json_from_api(),
  )
}

fn view(model: Model) {
  div([class("container mx-auto")], [
    div([class("relative py-15")], [
      view_jeopardy_table(model),
      div([], [text("something")]),
    ]),
  ])
}

// Main function to render the app
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
