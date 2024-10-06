import decoders/json_decoders.{type JsonCategories}
import lustre_http

pub type Model {
  Model(json_loaded: Bool, json_requested: Bool, json_content: JsonCategories)
}

pub type Msg {
  UserRequestsJson
  UserClickedField(Int)
  ApiReturnedJson(Result(JsonCategories, lustre_http.HttpError))
}
