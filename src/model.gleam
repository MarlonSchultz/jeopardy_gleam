import decoders/json_decoders.{type JsonCategories}
import lustre_http

pub type Model {
  Model(
    json_loaded: Bool,
    json_requested: Bool,
    json_content: JsonCategories,
    players: List(Player),
    modal_open: Modal,
  )
}

pub type Player {
  Player(name: String, points: Int, color: String)
}

pub type Modal {
  Question
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
