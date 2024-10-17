import decoders/json_decoders.{JsonCategories}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import lustre
import lustre/attribute.{class}
import lustre/effect
import lustre/element/html.{div, text}
import lustre/element/svg
import lustre/event
import lustre_http
import model.{
  type Model, type Msg, type Player, ApiReturnedJson, EditUser, Model, None,
  Player, Question, UserClickedPlayername, UserClickedQuestion, UserClosesModal,
  UserRequestsJson, UserSavedPlayername,
}

import lustre/animation
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

    UserClickedQuestion(_id) -> {
      let animation_svg = {
        animation.add(model.animation, "countdown", model.countdown, 0.0, 30.0)
        |> animation.add("svg_width", model.svg_width, 0.0, 29.0)
      }
      #(
        Model(..model, modal_open: Question(3), animation: animation_svg),
        animation.effect(animation_svg, model.Tick),
      )
    }
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
      let stop_animation = {
        animation.remove(model.animation, "countdown")
        |> animation.remove("svg_width")
      }
      #(
        Model(
          ..model,
          modal_open: None,
          countdown: 30.0,
          svg_width: 800.0,
          animation: stop_animation,
        ),
        effect.none(),
      )
    }
    model.EndTick(_time_offset) -> {
      io.debug("15 seconds passed")
      #(model, effect.none())
    }
    model.Tick(time_offset) -> {
      let new_animations = animation.tick(model.animation, time_offset)
      let new_countdown =
        animation.value(model.animation, "countdown", model.countdown)
      let svg_width =
        animation.value(model.animation, "svg_width", model.svg_width)
      let countdown = float.truncate(model.countdown)
      let effect = case countdown {
        count if count <= 0 -> animation.effect(model.animation, model.EndTick)
        _ -> animation.effect(model.animation, model.Tick)
      }
      #(
        Model(
          ..model,
          countdown: new_countdown,
          svg_width:,
          animation: new_animations,
        ),
        effect,
      )
    }

    _ -> #(model, effect.none())
  }
}

pub fn debug_foote(_timeout_id) {
  io.debug("debug_footer has been triggered")
  model.SomeMessage
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
      animation: animation.new(),
      countdown: 30.0,
      svg_width: 800.0,
    ),
    get_json_from_api(),
  )
}

fn question_modal(
  width_of_svg: Int,
  width_of_green: Float,
  countdown_string: String,
  model: Model,
) {
  case model.modal_open {
    model.Question(_) -> {
      let text_size = case int.parse(countdown_string) {
        Ok(number) -> {
          case int.is_odd(number) {
            True -> "24"
            False -> "30"
          }
        }
        Error(_) -> {
          "26"
        }
      }
      div([class("flex justify-center")], [
        div(
          [
            class(
              "absolute z-50 p-4 bg-blue-200 w-4/5 h-4/5 container flex flex-col justify-between mt-10 border-4 rounded-2xl",
            ),
          ],
          [
            div([class("flex-grow flex items-center justify-center")], [
              html.h1(
                [class("text-4xl font-bold text-black text-center mb-4")],
                [text("Answer")],
              ),
            ]),
            div([class("flex-grow flex items-center justify-center")], [
              svg.svg(
                [
                  attribute.attribute("width", width_of_svg |> int.to_string),
                  attribute.attribute("height", "60"),
                ],
                [
                  // red
                  svg.rect([
                    attribute.attribute("x", "0"),
                    attribute.attribute("y", "0"),
                    attribute.attribute("width", width_of_svg |> int.to_string),
                    attribute.attribute("height", "60"),
                    attribute.attribute("fill", "#f47d64"),
                  ]),
                  // green
                  svg.rect([
                    attribute.attribute("x", "0"),
                    attribute.attribute("y", "0"),
                    attribute.attribute(
                      "width",
                      width_of_green |> float.to_string,
                    ),
                    attribute.attribute("height", "60"),
                    attribute.attribute("fill", "#46b258"),
                  ]),
                  svg.text(
                    [
                      attribute.attribute(
                        "x",
                        width_of_svg / 2 |> int.to_string,
                      ),
                      attribute.attribute("y", "40"),
                      attribute.attribute("fill", "white"),
                      attribute.attribute("text-anchor", "middle"),
                      attribute.attribute("font-family", "Arial, sans-serif"),
                      attribute.attribute("font-size", text_size <> "px"),
                    ],
                    countdown_string,
                  ),
                ],
              ),
            ]),
            div([class("flex justify-center space-x-4")], [
              html.button(
                [
                  class(
                    "self-auto bg-green-500 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-green-400 hover:cursor-pointer hover:scale-125",
                  ),
                ],
                [text("Correct")],
              ),
              html.button(
                [
                  class(
                    "self-auto bg-red-300 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-red-200 hover:cursor-pointer hover:scale-125",
                  ),
                ],
                [text("Wrong")],
              ),
              html.button(
                [
                  class(
                    "self-auto bg-gray-400 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-gray-300 hover:cursor-pointer hover:scale-125",
                  ),
                  event.on_click(UserClosesModal),
                ],
                [text("Close question")],
              ),
            ]),
          ],
        ),
      ])
    }
    _ -> div([], [])
  }
}

fn view(model: Model) {
  div([class("min-h-screen flex flex-col mx-auto container")], [
    div([class("flex-grow py-15")], [
      question_modal(
        800,
        model.svg_width,
        model.countdown |> float.truncate |> int.to_string,
        model,
      ),
      view_jeopardy_table(model),
    ]),
    set_player_names_modal(model),
    html.footer(
      [class("w-full h-10 bg-gray-400 flex items-center")],
      get_player_names(model.players),
    ),
    div([], [text("debug_footer
    " <> float.to_string(model.svg_width) <> "  " <> float.to_string(
        model.countdown,
      ))]),
  ])
}

// Main function to render the app

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
