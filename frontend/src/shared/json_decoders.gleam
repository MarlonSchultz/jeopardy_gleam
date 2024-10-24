import gleam/dynamic

pub type Answer {
  Answer(id: Int, answer: String, question: String, points: Int)
}

pub fn decode_answer_list() -> fn(dynamic.Dynamic) ->
  Result(Answer, List(dynamic.DecodeError)) {
  dynamic.decode4(
    Answer,
    dynamic.field("id", dynamic.int),
    dynamic.field("answer", dynamic.string),
    dynamic.field("question", dynamic.string),
    dynamic.field("points", dynamic.int),
  )
}

// Type for a single category
pub type SingleCategory {
  SingleCategory(name: String, answers: List(Answer))
}

pub fn decode_single_category() -> fn(dynamic.Dynamic) ->
  Result(SingleCategory, List(dynamic.DecodeError)) {
  dynamic.decode2(
    SingleCategory,
    dynamic.field("category", dynamic.field("name", dynamic.string)),
    dynamic.field(
      "category",
      dynamic.field("answers", dynamic.list(decode_answer_list())),
    ),
  )
}

pub type JsonCategories {
  JsonCategories(categories: List(SingleCategory))
}

pub fn decode_json_categories() -> fn(dynamic.Dynamic) ->
  Result(JsonCategories, List(dynamic.DecodeError)) {
  dynamic.decode1(
    JsonCategories,
    dynamic.field("categories", dynamic.list(decode_single_category())),
  )
}
