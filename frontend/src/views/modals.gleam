import decoders/json_decoders.{type Answer, Answer}
import gleam/float
import gleam/int
import gleam/list
import lustre/attribute.{class}
import lustre/element/html.{div, text}
import lustre/element/svg
import lustre/event
import model.{UserClosesModal}

pub fn question_modal(
  width_of_svg: Int,
  width_of_green: Float,
  countdown_string: String,
  model: model.Model,
) {
  case model.modal_open {
    model.Question(question_id) -> {
      let #(visibility_question_css, button_text) = case model.reveal_question {
        True -> #("visible", "Hide")
        _ -> #("invisible", "Reveal")
      }

      div([class("flex justify-center")], [
        div(
          [
            class(
              "absolute z-50 p-4 bg-blue-200 w-4/5 h-4/5 container flex flex-col justify-between mt-10 border-4 rounded-2xl",
            ),
          ],
          [
            div([class("flex-grow flex flex-col items-center justify-center")], [
              // Answer
              html.h1(
                [class("text-4xl font-bold text-black text-center mb-4")],
                [text(filter_for_question(model, question_id).answer)],
              ),
              // Question
              html.h1(
                [
                  class(
                    "block text-4xl font-bold text-black text-center mt-20 whitespace-pre-line "
                    <> visibility_question_css,
                  ),
                ],
                [text(filter_for_question(model, question_id).question)],
              ),
            ]),
            div([class("flex-grow flex items-center justify-center")], [
              svg.svg(
                [
                  attribute.attribute("width", width_of_svg |> int.to_string),
                  attribute.attribute("height", "60"),
                ],
                [
                  // red
                  svg.rect([
                    attribute.attribute("x", "0"),
                    attribute.attribute("y", "0"),
                    attribute.attribute("width", width_of_svg |> int.to_string),
                    attribute.attribute("height", "60"),
                    attribute.attribute("fill", "#f47d64"),
                  ]),
                  // green
                  svg.rect([
                    attribute.attribute("x", "0"),
                    attribute.attribute("y", "0"),
                    attribute.attribute(
                      "width",
                      width_of_green |> float.to_string,
                    ),
                    attribute.attribute("height", "60"),
                    attribute.attribute("fill", "#46b258"),
                  ]),
                  svg.text(
                    [
                      attribute.attribute(
                        "x",
                        width_of_svg / 2 |> int.to_string,
                      ),
                      attribute.attribute("y", "40"),
                      attribute.attribute("fill", "white"),
                      attribute.attribute("text-anchor", "middle"),
                      attribute.attribute("font-family", "Arial, sans-serif"),
                      attribute.attribute(
                        "font-size",
                        text_size(countdown_string) <> "px",
                      ),
                    ],
                    countdown_string,
                  ),
                ],
              ),
            ]),
            div([class("flex justify-center space-x-4")], [
              html.button(
                [
                  class(
                    "self-auto bg-green-500 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-green-400 hover:cursor-pointer hover:scale-125",
                  ),
                ],
                [text("Correct")],
              ),
              html.button(
                [
                  class(
                    "self-auto bg-red-300 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-red-200 hover:cursor-pointer hover:scale-125",
                  ),
                ],
                [text("Wrong")],
              ),
              html.button(
                [
                  class(
                    "self-auto bg-gray-400 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-gray-300 hover:cursor-pointer hover:scale-125",
                  ),
                  event.on_click(UserClosesModal),
                ],
                [text("Close question (Do nothing)")],
              ),
              html.button(
                [
                  class(
                    "self-auto bg-gray-400 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-gray-300 hover:cursor-pointer hover:scale-125",
                  ),
                  event.on_click(model.UserClicksReveal),
                ],
                [text(button_text)],
              ),
            ]),
          ],
        ),
      ])
    }
    _ -> div([], [])
  }
}

fn filter_for_question(model: model.Model, search_id: Int) -> Answer {
  let result =
    list.find_map(model.json_content.categories, fn(category) {
      list.find(category.answers, fn(answer) {
        case answer {
          Answer(id, _, _, _) -> id == search_id
        }
      })
    })
  case result {
    Ok(answer) -> answer
    Error(_) ->
      Answer(
        id: 666,
        answer: "Decoder failed",
        question: "Decoder failed",
        points: -3000,
      )
  }
}

fn text_size(number: String) {
  case int.parse(number) {
    Ok(number) -> {
      case int.is_odd(number) {
        True -> "24"
        False -> "30"
      }
    }
    Error(_) -> {
      "26"
    }
  }
}
