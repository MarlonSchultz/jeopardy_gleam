import decoders/json_decoders
import gleam/int
import gleam/list
import lustre/attribute.{class}
import lustre/element
import lustre/element/html.{div, text}
import lustre/event
import model.{type Model, type Msg, Model, UserClickedField}

pub fn view_jeopardy_table(model: Model) -> element.Element(Msg) {
  let style_tr = "bg-blue-400 border-b"
  case model.json_loaded {
    True ->
      html.div([class("relative overflow-x-auto sm:rounded-lg bg-blue-200")], [
        html.table(
          [class("w-full text-sm text-center border-spacing-1 border-separate")],
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
              view_td_by_points(100, model.json_content.categories),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(200, model.json_content.categories),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(300, model.json_content.categories),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(400, model.json_content.categories),
            ),
            html.tr(
              [class(style_tr)],
              view_td_by_points(500, model.json_content.categories),
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
    html.th([class("px-6 py-3 rounded-xl")], [text(single.name)])
  })
}

fn view_td_by_points(
  points: Int,
  categories: List(json_decoders.SingleCategory),
) -> List(element.Element(Msg)) {
  list.map(filter_answers_by_points(categories, points), fn(answer) {
    html.td(
      [
        class("px-6 py-4 hover:bg-blue-500 rounded-xl"),
        event.on_click(UserClickedField(answer.id)),
      ],
      [text(int.to_string(answer.points))],
    )
  })
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
