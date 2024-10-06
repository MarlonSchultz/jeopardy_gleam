import decoders/json_decoders.{type JsonCategories}

pub type Model {
  Model(json_loaded: Bool, json_requested: Bool, json_content: JsonCategories)
}
