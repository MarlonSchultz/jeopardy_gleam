import config.{rest_server_url}
import gleam/float
import gleam/int
import lustre/attribute.{class}
import lustre/element/html.{div, text}
import lustre/element/svg
import lustre/event
import model.{UserClosesModal}
import shared/shared.{get_question_by_id}

pub fn question_modal(
  width_of_svg: Int,
  width_of_green: Float,
  countdown_string: String,
  model: model.Model,
) {
  case model.modal_open {
    model.Question(question_id) -> {
      let #(visibility_question_css, button_text) = case model.reveal_question {
        True -> #("block", "Hide")
        _ -> #("hidden", "Reveal")
      }

      let css_background_for_buzzed: String = {
        case model.buzzed {
          model.Red -> "bg-red-200 border-8 border-red-400"
          model.Yellow -> "bg-yellow-200 border-8 border-yellow-400"
          model.Blue -> "bg-blue-200 border-8 border-blue-400"
          model.Green -> "bg-green-200 border-8 border-green-400"
          model.NoOne -> "bg-slate-400 border-8 border-slate-700"
        }
      }

      let answer = case get_question_by_id(model, question_id).question_type {
        "question" ->
          html.h1([class("text-4xl font-bold text-black text-center mb-4")], [
            text(get_question_by_id(model, question_id).answer),
          ])
        _ ->
          html.img([
            attribute.class("h-[50%]"),
            attribute.attribute(
              "src",
              rest_server_url() <> get_question_by_id(model, question_id).answer,
            ),
          ])
      }
      div([class("flex")], [
        div(
          [
            class(
              "absolute z-50 p-4 w-4/5 h-4/5 container flex flex-col justify-between mt-10 rounded-2xl shadow-2xl shadow-black "
              <> css_background_for_buzzed,
            ),
          ],
          [
            div([class("flex-grow flex flex-col items-center justify-center")], [
              // Answer
              answer,
              // Question
              html.h1(
                [
                  class(
                    "block text-4xl font-bold text-black text-center mt-20 whitespace-pre-line "
                    <> visibility_question_css,
                  ),
                ],
                [text(get_question_by_id(model, question_id).question)],
              ),
            ]),
            div([class("flex-grow flex items-center justify-center")], [
              svg.svg(
                [
                  attribute.attribute("width", width_of_svg |> int.to_string),
                  attribute.attribute("height", "60"),
                  attribute.attribute("stroke", "15"),
                ],
                [
                  // red
                  svg.rect([
                    attribute.attribute("x", "0"),
                    attribute.attribute("y", "0"),
                    attribute.attribute("width", width_of_svg |> int.to_string),
                    attribute.attribute("height", "60"),
                    attribute.attribute("fill", "#f47d64"),
                    attribute.attribute("rx", "15"),
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
                    attribute.attribute("rx", "15"),
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
                    "self-auto bg-green-500 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-green-400 hover:cursor-pointer hover:scale-125 shadow-lg border-2",
                  ),
                  event.on_click(model.UserClickedCorrect(
                    get_question_by_id(model, question_id).points,
                    question_id,
                  )),
                ],
                [text("Correct")],
              ),
              html.button(
                [
                  class(
                    "self-auto bg-red-300 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-red-200 hover:cursor-pointer hover:scale-125 shadow-lg border-2",
                  ),
                  event.on_click(model.UserClickedCorrect(
                    -get_question_by_id(model, question_id).points,
                    question_id,
                  )),
                ],
                [text("Wrong")],
              ),
              html.button(
                [
                  class(
                    "self-auto bg-gray-400 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-gray-300 hover:cursor-pointer hover:scale-125 shadow-lg border-2",
                  ),
                  event.on_click(UserClosesModal),
                ],
                [text("Close question (Do nothing)")],
              ),
              html.button(
                [
                  class(
                    "self-auto bg-gray-400 text-white px-4 py-2 rounded transition ease-in-out delay-150 hover:bg-gray-300 hover:cursor-pointer hover:scale-125 shadow-lg border-2",
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
