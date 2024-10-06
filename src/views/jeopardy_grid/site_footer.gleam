import gleam/list
import lustre/attribute.{class}
import lustre/element.{text}
import lustre/element/html.{button}
import lustre/event
import model.{type Msg, type Player, Player, UserClickedPlayername}

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
      [text(player.color <> player.name <> " | ")],
    )
  })
}
