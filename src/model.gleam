import decoders/json_decoders.{type JsonCategories}
import gleam/option.{type Option}
import lustre_http
import repeatedly.{type Repeater}

pub type Model {
  Model(
    json_loaded: Bool,
    json_requested: Bool,
    json_content: JsonCategories,
    players: List(Player),
    modal_open: Modal,
    modal_timer: Int,
    modal_timer_running: Bool,
    repeater_instance: Option(Repeater(Int)),
  )
}

pub type Player {
  Player(name: String, points: Int, color: String)
}

pub type Modal {
  Question(Int)
  EditUser(Player)
  None
}

pub type Msg {
  UserRequestsJson
  UserClosesModal
  UserClickedQuestion(Int)
  UserClickedPlayername(Player)
  UserSavedPlayername(Player)
  ApiReturnedJson(Result(JsonCategories, lustre_http.HttpError))
}
