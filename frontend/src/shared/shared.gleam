import gleam/list
import model
import shared/json_decoders.{type Answer, Answer}

pub fn get_question_by_id(model: model.Model, search_id: Int) -> Answer {
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

pub fn calculate_new_points_for_player(
  players: List(model.Player),
  points: Int,
  buzzer: model.Buzzer,
) -> List(model.Player) {
  list.map(players, fn(player) {
    case player.player_id == buzzer {
      True ->
        model.Player(
          ..player,
          name: "for testing",
          points: player.points + points,
        )
      _ -> player
    }
  })
}
