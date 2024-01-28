defmodule Jahns.Game do
  alias Jahns.Player

  @derive Jason.Encoder
  defstruct messages: [],
            map: Jahns.Map.new(),
            slug: nil,
            state: :setup,
            turn: nil,
            result: nil,
            players: []

  def new(slug) do
    struct!(
      __MODULE__,
      messages: [
        "game #{slug} created, waiting for players"
      ],
      slug: slug
    )
  end

  def start_game(game) do
    raise "not implemented"
  end

  def end_game(game, result) do
    raise "not implemented"
  end

  def game_active(game) do
    if game.state == :active do
      :ok
    else
      {:error, :game_not_active}
    end
  end

  def it_is_my_turn(game, player) do
    raise "not implemented"
  end

  def is_player_host?(game, player) when not is_nil(player) do
    Enum.at(game.players, 0).id == player.id
  end

  def player_can_start_game?(game, player) do
    is_player_host?(game, player) && length(game.players) >= 2
  end

  def result(game) do
    raise "not implemented"
  end

  def next_turn(game) do
    raise "not implemented"
  end

  def add_player(game, player_id, player_name) do
    if game.state == :setup do
      if length(game.players) >= 4 do
        {:error, :game_full}
      else
        player = Player.new(player_id, player_name)

        game =
          game
          |> Map.put(:players, game.players ++ [player])
          |> new_message("player #{player.name} #{player.art |> elem(1)} joined")

        {:ok, game, player}
      end
    else
      {:error, :game_not_in_setup}
    end
  end

  def new_message(game, message) do
    game |> Map.put(:messages, [message | game.messages])
  end

  def get_player_by_id(game, player_id) do
    player = Enum.find(game.players, fn player -> player.id == player_id end)

    if player do
      {:ok, player}
    else
      {:error, :player_not_found}
    end
  end
end
