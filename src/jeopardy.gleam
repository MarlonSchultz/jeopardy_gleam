import decoders/json_decoders.{JsonCategories}

import gleam/list
import lustre
import lustre/attribute.{class}
import lustre/effect
import lustre/element/html.{div}
import lustre_http
import model.{
  type Model, type Msg, type Player, ApiReturnedJson, EditUser, Model, None,
  Player, UserClickedField, UserClickedPlayername, UserClosesModal,
  UserRequestsJson, UserSavedPlayername,
}
import views/jeopardy_grid/jeopardy_table.{view_jeopardy_table}
import views/jeopardy_grid/site_footer.{get_player_names, set_player_names_modal}

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
    UserClickedPlayername(player) -> #(
      Model(..model, modal_open: EditUser(player)),
      effect.none(),
    )
    UserSavedPlayername(new_player_record) -> {
      let new_players =
        list.map(model.players, fn(player) {
          case player.color == new_player_record.color {
            True -> Player(..player, name: new_player_record.name)
            _ -> player
          }
        })
      #(Model(..model, players: new_players, modal_open: None), effect.none())
    }
    UserClosesModal -> {
      #(Model(..model, modal_open: None), effect.none())
    }
  }
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    model.Model(
      json_loaded: False,
      json_requested: False,
      json_content: JsonCategories([]),
      players: [
        Player("Player1", 0, "🔴"),
        Player("Player2", 0, "🟢"),
        Player("Player3", 0, "🔵"),
        Player("Player4", 0, "🟡"),
      ],
      modal_open: None,
    ),
    get_json_from_api(),
  )
}

fn view(model: Model) {
  div([class("min-h-screen flex flex-col mx-auto container")], [
    div([class("flex-grow py-15")], [view_jeopardy_table(model)]),
    set_player_names_modal(model),
    html.footer(
      [class("w-full h-10 bg-gray-400 flex items-center")],
      get_player_names(model.players),
    ),
  ])
}

// Main function to render the app
pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
