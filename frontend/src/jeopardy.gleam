import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import lustre
import lustre/animation
import lustre/attribute.{class}
import lustre/effect
import lustre/element/html.{div, text}
import lustre_http
import lustre_websocket.{OnOpen} as websocket
import model.{
  type Model, type Msg, type Player, ApiReturnedJson, Blue, EditUser, Green,
  Model, Nothing, Player, Question, Red, SystemClosesQuestionServerSide,
  UserClickedCorrect, UserClickedPlayername, UserClickedQuestion,
  UserClosesModal, UserRequestsJson, UserSavedPlayername, WsWrapper, Yellow,
}
import shared/json_decoders.{JsonCategories}
import shared/shared
import views/jeopardy_table.{view_jeopardy_table}
import views/modals.{question_modal}
import views/site_footer.{get_player_names, set_player_names_modal}

fn get_json_from_api() -> effect.Effect(Msg) {
  let expect =
    lustre_http.expect_json(
      json_decoders.decode_json_categories(),
      ApiReturnedJson,
    )
  lustre_http.get("http://localhost:8888/questions", expect)
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

    UserClickedQuestion(id) -> {
      case model.websocket {
        Some(ws) -> #(
          Model(..model, modal_open: Question(id)),
          websocket.send(ws, "Question open"),
        )
        None -> #(model, effect.none())
      }
    }
    UserClickedPlayername(player) -> {
      #(
        Model(..model, modal_open: EditUser(player)),
        effect.batch([
          effect.from(fn(callback) { callback(model.SystemStopsCountdown) }),
          effect.from(fn(callback) {
            callback(model.SystemClosesQuestionServerSide)
          }),
        ]),
      )
    }
    UserSavedPlayername(new_player_record) -> {
      let new_players =
        list.map(model.players, fn(player) {
          case player.player_id == new_player_record.player_id {
            True -> Player(..player, name: new_player_record.name)
            _ -> player
          }
        })
      #(
        Model(..model, players: new_players, modal_open: Nothing),
        effect.none(),
      )
    }

    SystemClosesQuestionServerSide -> {
      case model.websocket {
        Some(ws) -> #(model, websocket.send(ws, "Question closed"))
        None -> #(model, effect.none())
      }
    }

    UserClosesModal -> {
      case model.websocket {
        Some(ws) -> #(
          Model(..model, modal_open: Nothing, buzzed: model.NoOne),
          effect.batch([
            websocket.send(ws, "Question closed"),
            effect.from(fn(callback) { callback(model.SystemStopsCountdown) }),
          ]),
        )
        None -> #(
          Model(..model, modal_open: Nothing, buzzed: model.NoOne),
          effect.from(fn(callback) { callback(model.SystemStopsCountdown) }),
        )
      }
    }

    model.SystemStopsCountdown -> {
      let stop_animation = {
        animation.remove(model.animation, "countdown")
        |> animation.remove("svg_width")
      }
      #(
        Model(
          ..model,
          countdown: 30.0,
          svg_width: 800.0,
          animation: stop_animation,
          buzzed: model.NoOne,
        ),
        effect.none(),
      )
    }

    model.EndTick(_time_offset) -> {
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
    model.UserClicksReveal -> {
      #(Model(..model, reveal_question: !model.reveal_question), effect.none())
    }

    WsWrapper(OnOpen(socket)) -> #(
      Model(..model, websocket: Some(socket)),
      websocket.send(socket, "client-init"),
    )

    WsWrapper(websocket.OnClose(_)) -> #(
      Model(..model, websocket: None),
      websocket.init("ws://localhost:8888/websocket", model.WsWrapper),
    )

    WsWrapper(websocket.OnTextMessage(msg)) -> {
      io.debug(msg)
      let buzzer = case msg {
        "red" -> model.Red
        "blue" -> model.Blue
        "yellow" -> model.Yellow
        "green" -> model.Green
        _ -> model.NoOne
      }

      let animation_svg = {
        animation.add(model.animation, "countdown", model.countdown, 0.0, 30.0)
        |> animation.add("svg_width", model.svg_width, 0.0, 29.0)
      }
      #(
        Model(..model, buzzed: buzzer, animation: animation_svg),
        animation.effect(animation_svg, model.Tick),
      )
    }

    UserClickedCorrect(question_points, question_id) -> {
      case model.buzzed {
        // no one buzzed, no need to hide
        model.NoOne -> #(model, effect.none())
        _ -> {
          let new_players =
            shared.calculate_new_points_for_player(
              model.players,
              question_points,
              model.buzzed,
            )

          let new_answered =
            list.append(model.answered, [
              model.AnsweredQuestions(id: question_id, buzzed: model.Red),
            ])

          #(
            Model(..model, players: new_players, answered: new_answered),
            effect.from(fn(callback) { callback(model.UserClosesModal) }),
          )
        }
      }
    }

    _ -> #(model, effect.none())
  }
}

fn init(_flags) -> #(Model, effect.Effect(Msg)) {
  #(
    model.Model(
      json_loaded: False,
      json_requested: False,
      json_content: JsonCategories([]),
      players: [
        Player("Player1", 0, "🔴", Red),
        Player("Player2", 0, "🟢", Green),
        Player("Player3", 0, "🔵", Blue),
        Player("Player4", 0, "🟡", Yellow),
      ],
      modal_open: Nothing,
      animation: animation.new(),
      countdown: 30.0,
      svg_width: 800.0,
      reveal_question: False,
      websocket: None,
      buzzed: model.NoOne,
      answered: [model.AnsweredQuestions(id: 0, buzzed: model.NoOne)],
    ),
    effect.batch([
      get_json_from_api(),
      websocket.init("ws://localhost:8888/websocket", model.WsWrapper),
    ]),
  )
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
    div([], [text("Socket: " <> websocket_debug(model.websocket))]),
  ])
}

fn websocket_debug(ws: option.Option(websocket.WebSocket)) {
  case ws {
    option.Some(_) -> "Websocket connected"
    _ -> "Websocket not connected"
  }
}

// Main function to render the app

pub fn main() {
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
