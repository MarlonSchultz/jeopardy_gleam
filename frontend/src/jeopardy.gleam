import decoders/json_decoders.{JsonCategories}
import gleam/float
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import grille_pain
import grille_pain/lustre/toast
import lustre
import lustre/animation
import lustre/attribute.{class}
import lustre/effect
import lustre/element/html.{div, text}
import lustre_http
import lustre_websocket.{OnOpen} as websocket
import model.{
  type Model, type Msg, type Player, ApiReturnedJson, DisplayBasicToast,
  EditUser, Model, Nothing, Player, Question, UserClickedPlayername,
  UserClickedQuestion, UserClosesModal, UserRequestsJson, UserSavedPlayername,
  WsWrapper,
}
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
      let animation_svg = {
        animation.add(model.animation, "countdown", model.countdown, 0.0, 30.0)
        |> animation.add("svg_width", model.svg_width, 0.0, 29.0)
      }

      case model.websocket {
        Some(ws) -> #(
          Model(..model, modal_open: Question(id), animation: animation_svg),
          effect.batch([
            animation.effect(animation_svg, model.Tick),
            websocket.send(ws, "Question open"),
          ]),
        )
        None -> #(model, effect.none())
      }
    }
    UserClickedPlayername(player) -> {
      let stop_animation = {
        animation.remove(model.animation, "countdown")
        |> animation.remove("svg_width")
      }
      #(
        Model(
          ..model,
          modal_open: EditUser(player),
          countdown: 30.0,
          svg_width: 800.0,
          animation: stop_animation,
        ),
        effect.none(),
      )
    }
    UserSavedPlayername(new_player_record) -> {
      let new_players =
        list.map(model.players, fn(player) {
          case player.color == new_player_record.color {
            True -> Player(..player, name: new_player_record.name)
            _ -> player
          }
        })
      #(
        Model(..model, players: new_players, modal_open: Nothing),
        effect.none(),
      )
    }
    UserClosesModal -> {
      let stop_animation = {
        animation.remove(model.animation, "countdown")
        |> animation.remove("svg_width")
      }
      case model.websocket {
        Some(ws) -> #(
          Model(
            ..model,
            modal_open: Nothing,
            countdown: 30.0,
            svg_width: 800.0,
            animation: stop_animation,
          ),
          websocket.send(ws, "Question closed"),
        )
        None -> #(model, effect.none())
      }
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
    model.UserClicksReveal -> {
      #(Model(..model, reveal_question: !model.reveal_question), effect.none())
    }
    WsWrapper(OnOpen(socket)) -> #(
      Model(..model, websocket: Some(socket)),
      websocket.send(socket, "client-init"),
    )
    WsWrapper(websocket.OnTextMessage(msg)) -> {
      let buzzer = case msg {
        "Buzzer red pressed" -> model.Red
        "buzzer release" -> model.NoOne
        _ -> model.NoOne
      }
      #(
        Model(..model, buzzed: buzzer),
        effect.from(fn(callback) { dispatch_as_toast(buzzer, callback) }),
      )
    }

    DisplayBasicToast(content) -> {
      let style_of_toast = case model.buzzed {
        model.Blue -> toast.info(content)
        model.Green -> toast.success(content)
        model.Red -> toast.error(content)
        _ -> toast.warning(content)
      }
      #(model, style_of_toast)
    }

    _ -> #(model, effect.none())
  }
}

fn dispatch_as_toast(buzzed: model.Buzzer, callback: fn(Msg) -> Nil) -> Nil {
  case buzzed {
    model.Red -> callback(DisplayBasicToast("Red buzzed"))
    model.Green -> callback(DisplayBasicToast("Green buzzed"))
    model.Yellow -> callback(DisplayBasicToast("Yellow buzzed"))
    model.Blue -> callback(DisplayBasicToast("Blue buzzed"))
    _ -> Nil
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
      modal_open: Nothing,
      animation: animation.new(),
      countdown: 30.0,
      svg_width: 800.0,
      reveal_question: False,
      websocket: None,
      buzzed: model.NoOne,
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
    div([], [text("debug_footer
    " <> float.to_string(model.svg_width) <> "  " <> float.to_string(
        model.countdown,
      ) <> " " <> buzzed_to_string(model.buzzed))]),
  ])
}

fn buzzed_to_string(buzzed: model.Buzzer) {
  case buzzed {
    model.Red -> "Red"
    _ -> "No buzz!"
  }
}

// Main function to render the app

pub fn main() {
  let assert Ok(_) = grille_pain.simple()
  let app = lustre.application(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}
