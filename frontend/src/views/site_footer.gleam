import decipher
import gleam/dynamic
import gleam/int
import gleam/list
import gleam/result
import lustre/attribute.{class}
import lustre/element.{text}
import lustre/element/html.{button, div}
import lustre/event
import model.{
  type Model, type Msg, type Player, EditUser, Player, UserClickedPlayername,
  UserClosesModal, UserSavedPlayername,
}

pub fn get_player_names(players: List(Player)) -> List(element.Element(Msg)) {
  players
  |> list.map(fn(player) {
    button(
      [
        class(
          "transition ease-in-out delay-150 hover:bg-blue-200 hover:cursor-pointer hover:scale-110 pl-5",
        ),
        event.on_click(UserClickedPlayername(player)),
      ],
      [
        text(
          player.color
          <> " "
          <> player.name
          <> ": "
          <> int.to_string(player.points)
          <> " |",
        ),
      ],
    )
  })
}

pub fn set_player_names_modal(model: Model) -> element.Element(Msg) {
  case model.modal_open {
    EditUser(player) -> {
      let Player(name, _, _, _) = player
      let path = ["target", "previousElementSibling", "value"]
      let handle_input = fn(e) {
        e
        |> decipher.at(path, dynamic.string)
        |> result.nil_error
        |> result.map(fn(new_name) {
          UserSavedPlayername(Player(..player, name: new_name))
        })
        |> result.replace_error([])
      }

      html.div([class("inline-flex items-center space-x-2 pb-5 pl-5")], [
        html.input([
          class(
            "font-bold block bg-blue-200 w-1000 border border-slate-300 rounded-md py-2 pl-9 pr-3 shadow-sm focus:outline-none focus:border-sky-500 focus:ring-1 sm:text-sm",
          ),
          attribute.type_("text"),
          attribute.value(name),
          event.on("update", handle_input),
        ]),
        html.button(
          [
            event.on("click", handle_input),
            class(
              "bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded",
            ),
          ],
          [text("Do it!")],
        ),
        html.button(
          [
            event.on_click(UserClosesModal),
            class(
              "bg-yellow-500 hover:bg-red-300 text-white font-bold py-2 px-4 rounded",
            ),
          ],
          [text("Meh.")],
        ),
      ])
    }
    _ -> div([], [])
  }
}
