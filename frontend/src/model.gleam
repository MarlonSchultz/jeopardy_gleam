import decoders/json_decoders.{type JsonCategories}
import gleam/option.{type Option}
import lustre/animation
import lustre_http
import lustre_websocket as websocket

pub type Model {
  Model(
    json_loaded: Bool,
    json_requested: Bool,
    json_content: JsonCategories,
    players: List(Player),
    modal_open: Modal,
    animation: animation.Animations,
    countdown: Float,
    svg_width: Float,
    reveal_question: Bool,
    websocket: Option(websocket.WebSocket),
  )
}

pub type Player {
  Player(name: String, points: Int, color: String)
}

pub type Modal {
  Question(Int)
  EditUser(Player)
  Nothing
}

pub type Msg {
  UserRequestsJson
  UserClosesModal
  UserClickedQuestion(Int)
  UserClickedPlayername(Player)
  UserSavedPlayername(Player)
  ApiReturnedJson(Result(JsonCategories, lustre_http.HttpError))
  Trigger
  Tick(Float)
  EndTick(Float)
  SomeMessage
  AnimationCompleted(animation.TimeoutId)
  UserClicksReveal
  WsWrapper(websocket.WebSocketEvent)
}
