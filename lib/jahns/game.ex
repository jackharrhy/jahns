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

  def move_active_player(game, value) do
    IO.inspect("move_active_player #{value}")

    {:ok, player} = get_player_by_id(game, game.turn)
    player_node_id = player.node |> elem(0)

    nodes = Jahns.Map.nodes_connected_to_node(game.map, player_node_id)

    # TODO for now, pick random node
    # in the future, if only one node, just move
    # if more than one, let player choose
    to_node = Enum.random(nodes)

    player = Map.put(player, :node, to_node)

    game = update_player(game, player)

    moves_left = value - 1

    post_message =
      if moves_left > 0 do
        {500, {:move_active_player, value - 1}}
      else
        # TODO the game should be in a busy state while the player is moving
        # therefore we should send a message that puts the game back into
        # a ready state once the player has finished moving
        nil
      end

    {:ok, game, post_message}
  end

  def use_card(_game, player, card) when player.energy < card.cost do
    {:error, :not_enough_energy}
  end

  def use_card(game, player, card) do
    base_message = "#{player} used #{card.name} costing #{card.cost} energy"

    player = Map.put(player, :energy, player.energy - card.cost)

    {game, post_message} =
      case card.action do
        :move ->
          %{low_value: low_value, high_value: high_value} = card
          value = Enum.random(low_value..high_value)

          post_message =
            if value > 0 do
              {500, {:move_active_player, value}}
            else
              nil
            end

          game = game |> new_message("#{base_message}, will move by #{value} spaces")

          {game, post_message}

        _ ->
          raise "unhandled action"
      end

    hand = Enum.filter(player.hand, fn c -> c.id != card.id end)
    player = Map.put(player, :hand, hand)

    discard_pile = player.discard_pile ++ [card]
    player = Map.put(player, :discard_pile, discard_pile)

    game = update_player(game, player)

    {:ok, game, post_message}
  end

  def update_player(game, player) do
    Map.put(
      game,
      :players,
      Enum.map(game.players, fn p ->
        if p.id == player.id do
          player
        else
          p
        end
      end)
    )
  end

  def attempt_to_use_card(game, player_id, card_id) do
    with :ok <- game_in_state(game, :active),
         {:ok, player} <- get_player_by_id(game, player_id),
         :ok <- is_players_turn(game, player),
         {:ok, card} <- card_id_to_card_in_hand(player, card_id),
         {:ok, game, post_message} <- use_card(game, player, card) do
      {:ok, game, post_message}
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

  def game_in_state(_game, _state) do
    {:error, :game_not_in_required_state}
  end

  def is_player_host?(player) when not is_nil(player) do
    player.index == 0
  end

  def player_can_start_game?(game, player) do
    game_in_state(game, :setup) == :ok && is_player_host?(player) && length(game.players) >= 2
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
