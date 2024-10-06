import decoders/json_decoders.{JsonCategories}
import lustre
import lustre/attribute.{class}
import lustre/effect
import lustre/element/html.{div, text}
import lustre_http
import model.{
  type Model, type Msg, ApiReturnedJson, Model, UserClickedField,
  UserRequestsJson,
}
import views/jeopardy_grid/jeopardy_table.{view_jeopardy_table}

fn get_json_from_api() -> effect.Effect(Msg) {
  let expect =
    lustre_http.expect_json(
      json_decoders.decode_json_categories(),
      ApiReturnedJson,
    )
  lustre_http.get("http://localhost:8080/answers.json", expect)
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

    UserClickedField(_id) -> #(model, effect.none())
  }
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    model.Model(
      json_loaded: False,
      json_requested: False,
      json_content: JsonCategories([]),
    ),
    get_json_from_api(),
  )
}

fn view(model: Model) {
  div([class("min-h-screen flex flex-col mx-auto container")], [
    div([class("flex-grow py-15")], [view_jeopardy_table(model)]),
    html.footer([class("w-full h-10 bg-gray-400 flex items-center")], [
      text("🔴 Player 1 | "),
      text("🟢 Player 2 | "),
      text("🔵 Player 3 | "),
      text("🟡 Player 4 | "),
    ]),
  ])
}

// Main function to render the app
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
