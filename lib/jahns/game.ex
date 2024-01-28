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

  def start_game(game, player_id) do
    {:ok, player} = get_player_by_id(game, player_id)

    if game.state == :setup and player_can_start_game?(game, player) do
      random_player = Enum.random(game.players)

      game =
        game
        |> Map.put(:state, :active)
        |> Map.put(:turn, random_player.id)

      game =
        game
        |> new_message("game started by #{player}")
        |> new_message("it is #{random_player}'s turn")

      {:ok, game}
    else
      {:error, :cannot_start_game}
    end
  end

  def use_card(card) do
    IO.inspect(["card", card])

    {:ok, []}
  end

  def apply_effects(game, effects) do
    IO.inspect(["effects", effects])

    {:ok, game}
  end

  def use_card(game, player_id, card_id) do
    with :ok <- game_in_state(game, :active),
         {:ok, player} <- get_player_by_id(game, player_id),
         :ok <- is_players_turn(game, player),
         {:ok, card} <- card_id_to_card_in_hand(player, card_id),
         {:ok, effects} <- use_card(card),
         {:ok, game} <- apply_effects(game, effects) do
      {:ok, game}
    end
  end

  def is_players_turn?(game, player_id) do
    game.turn == player_id
  end

  def is_players_turn(game, player) do
    if is_players_turn?(game, player.id) do
      :ok
    else
      {:error, :not_players_turn}
    end
  end

  def card_id_to_card_in_hand(player, card_id) do
    if card = Enum.find(player.hand, fn card -> card.id == card_id end) do
      {:ok, card}
    else
      {:error, :card_not_in_hand}
    end
  end

  def game_in_state(game, state) when game.state == state do
    :ok
  end

  def game_in_state(game, state) do
    {:error, :game_not_in_required_state}
  end

  def is_player_host?(player) when not is_nil(player) do
    player.index == 0
  end

  def player_can_start_game?(game, player) do
    is_player_host?(player) && length(game.players) >= 2
  end

  def add_player(game, player_id, player_name) do
    if game.state == :setup do
      if length(game.players) >= 4 do
        {:error, :game_full}
      else
        player_index = length(game.players)

        starting_node = game.map.nodes |> Enum.at(0)

        player = Player.new(player_id, player_name, player_index, starting_node)

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
