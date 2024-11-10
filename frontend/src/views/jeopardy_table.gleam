import gleam/int
import gleam/list
import lustre/attribute.{class}
import lustre/element
import lustre/element/html.{div, text}
import lustre/event
import model.{type Model, type Msg, Model, UserClickedQuestion}
import shared/json_decoders

pub fn view_jeopardy_table(model: Model) -> element.Element(Msg) {
  let style_tr =
    "bg-blue-400 border-b text-3xl font-bold text-black text-center"
  case model.json_loaded {
    True ->
      html.div([class("relative overflow-x-auto sm:rounded-lg bg-blue-200")], [
        html.table(
          [
            class(
              "w-full text-sm text-center border-spacing-1 border-separate table-fixed",
            ),
          ],
          [
            html.thead([class("text-xs text-gray-700 uppercase bg-blue-700")], [
              html.tr(
                [
                  class(
                    "w-full text-sm text-center text-gray-500 dark:text-gray-400",
                  ),
                ],
                view_th(model.json_content.categories),
              ),
            ]),
            html.tr(
              [class(style_tr)],
              view_td_by_points(
                100,
                model.json_content.categories,
                model.answered,
              ),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(
                200,
                model.json_content.categories,
                model.answered,
              ),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(
                300,
                model.json_content.categories,
                model.answered,
              ),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(
                400,
                model.json_content.categories,
                model.answered,
              ),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(
                500,
                model.json_content.categories,
                model.answered,
              ),
            ),
          ],
        ),
      ])
    _ -> div([], [text("Something went wrong in parsing JSON, or API calling")])
  }
}

fn view_th(
  lists: List(json_decoders.SingleCategory),
) -> List(element.Element(a)) {
  list.map(lists, fn(single) {
    html.th(
      [
        class(
          "px-6 py-3 rounded-xl text-2xl font-bold text-black text-center animate-text bg-gradient-to-r from-teal-500 via-purple-500 to-orange-500 bg-clip-text text-transparent font-black",
        ),
      ],
      [text(single.name)],
    )
  })
}

fn view_td_by_points(
  points: Int,
  categories: List(json_decoders.SingleCategory),
  answered: List(model.AnsweredQuestions),
) -> List(element.Element(Msg)) {
  list.map(filter_answers_by_points(categories, points), fn(answer) {
    html.td(
      [
        class(
          "px-6 py-4 hover:bg-blue-500 rounded-xl transition ease-in-out delay-150 duration-500 hover:cursor-pointer hover:scale-110 "
          <> mark_answer_by_player(answer.id, answered),
        ),
        event.on_click(UserClickedQuestion(answer.id)),
      ],
      [text(int.to_string(answer.points))],
    )
  })
}

fn mark_answer_by_player(
  answer_id: Int,
  answered: List(model.AnsweredQuestions),
) -> String {
  let buzzercolor = case
    list.find(answered, fn(single_answer) { single_answer.id == answer_id })
  {
    Ok(list_item) -> list_item.buzzed
    Error(_) -> model.NoOne
  }

  case buzzercolor {
    model.Blue -> "bg-blue-500 transition-colors duration-500"
    model.Green -> "bg-green-500 transition-colors duration-500"
    model.NoOne ->
      "bg-gradient-to-b from-cyan-500 to-blue-500 transition-colors duration-500"
    model.Red -> "bg-red-500 transition-colors duration-500"
    model.Yellow -> "bg-yellow-500 transition-colors duration-500"
  }
}

fn filter_answers_by_points(
  categories: List(json_decoders.SingleCategory),
  target_points: Int,
) -> List(json_decoders.Answer) {
  categories
  |> list.map(fn(category) {
    category.answers
    |> list.filter(fn(answer) {
      case answer {
        json_decoders.Answer(points: points, ..) if points == target_points ->
          True
        _ -> False
      }
    })
  })
  |> list.concat
}
