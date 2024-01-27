defmodule Jahns.Game do
  alias Jahns.Player

  @derive Jason.Encoder
  defstruct slug: nil,
            state: :setup,
            turn: nil,
            result: nil,
            players: []

  def new(slug) do
    struct!(__MODULE__, slug: slug)
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

  def result(game) do
    raise "not implemented"
  end

  def next_turn(game) do
    raise "not implemented"
  end

  def add_player(game, player_id, player_name) do
    raise "not implemented"
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
