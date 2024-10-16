import decoders/json_decoders.{JsonCategories}
import gleam/int
import gleam/io
import gleam/list
import gleam/option
import lustre
import lustre/attribute.{class}
import lustre/effect
import lustre/element/html.{div, text}
import lustre/element/svg
import lustre_http
import model.{
  type Model, type Msg, type Player, ApiReturnedJson, EditUser, Model, None,
  Player, Question, UserClickedPlayername, UserClickedQuestion, UserClosesModal,
  UserRequestsJson, UserSavedPlayername,
}
import repeatedly
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

    UserClickedQuestion(_id) -> #(
      Model(..model, modal_open: Question(3)),
      effect.none(),
    )
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
      modal_timer: 30,
      modal_timer_running: False,
      repeater_instance: option.None,
      // None, Question, EditUser See: model.gleam
    ),
    get_json_from_api(),
  )
}

fn question_modal(
  width_of_svg: Int,
  width_of_green: Int,
  text_to_show: String,
  model: Model,
) {
  case model.modal_open {
    model.Question(_) ->
      div([class("flex justify-center")], [
        div(
          [
            class(
              "absolute z-50 p-4 bg-blue-200 w-4/5 h-4/5 container flex flex-col justify-between mt-10 border-4 rounded-2xl",
            ),
          ],
          [
            div([class("flex-grow flex items-center justify-center")], [
              html.h1([], [text("Answer")]),
            ]),
            div([class("flex-grow flex items-center justify-center")], [
              svg.svg(
                [
                  attribute.attribute("width", width_of_svg |> int.to_string),
                  attribute.attribute("height", "40"),
                ],
                [
                  // red
                  svg.rect([
                    attribute.attribute("x", "0"),
                    attribute.attribute("y", "0"),
                    attribute.attribute("width", width_of_svg |> int.to_string),
                    attribute.attribute("height", "40"),
                    attribute.attribute("fill", "#f47d64"),
                  ]),
                  // green
                  svg.rect([
                    attribute.attribute("x", "0"),
                    attribute.attribute("y", "0"),
                    attribute.attribute(
                      "width",
                      width_of_green |> int.to_string,
                    ),
                    attribute.attribute("height", "40"),
                    attribute.attribute("fill", "#46b258"),
                  ]),
                  svg.text(
                    [
                      attribute.attribute(
                        "x",
                        width_of_svg / 2 |> int.to_string,
                      ),
                      attribute.attribute("y", "25"),
                      attribute.attribute("fill", "white"),
                      attribute.attribute("text-anchor", "middle"),
                    ],
                    text_to_show,
                  ),
                ],
              ),
            ]),
          ],
        ),
      ])
    _ -> div([], [])
  }
}

fn view(model: Model) {
  div([class("min-h-screen flex flex-col mx-auto container")], [
    div([class("flex-grow py-15")], [
      question_modal(800, 400, "seconds remaining", model),
      view_jeopardy_table(model),
    ]),
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

  let external = 1
  let repeater =
    repeatedly.call(500, external, fn(state, i) {
      let state = state + 1
    })

  io.debug(repeater)

  Nil
}
