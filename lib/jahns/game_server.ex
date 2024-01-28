defmodule Jahns.GameServer do
  use GenServer

  require Logger

  alias Jahns.Game

  def add_player(slug, player_id, player_name) do
    with {:ok, game, player} <- call_by_slug(slug, {:add_player, player_id, player_name}) do
      broadcast_game_updated!(slug, game)
      {:ok, game, player}
    end
  end

  def get_game(slug) do
    call_by_slug(slug, :get_game)
  end

  def get_player_by_id(slug, player_id) do
    call_by_slug(slug, {:get_player_by_id, player_id})
  end

  defp call_by_slug(slug, command) do
    case game_pid(slug) do
      game_pid when is_pid(game_pid) ->
        GenServer.call(game_pid, command)

      nil ->
        {:error, :game_not_found}
    end
  end

  def start_link(slug) do
    GenServer.start(__MODULE__, slug, name: via_tuple(slug))
  end

  def game_pid(slug) do
    slug
    |> via_tuple()
    |> GenServer.whereis()
  end

  def game_exists?(slug) do
    game_pid(slug) != nil
  end

  @impl GenServer
  def init(slug) do
    Logger.info("Creating game server with slug #{slug}")
    {:ok, %{game: Game.new(slug)}}
  end

  @impl GenServer
  def handle_call({:add_player, player_id, player_name}, _from, state) do
    case Game.add_player(state.game, player_id, player_name) do
      {:ok, game, player} ->
        {:reply, {:ok, game, player}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call(:get_game, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl GenServer
  def handle_call({:get_player_by_id, player_id}, _from, state) do
    {:reply, Game.get_player_by_id(state.game, player_id), state}
  end

  defp broadcast_game_updated!(slug, game) do
    broadcast!(slug, :game_updated, %{game: game})
  end

  def broadcast!(slug, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(Jahns.PubSub, slug, %{event: event, payload: payload})
  end

  defp via_tuple(slug) do
    {:via, Registry, {Jahns.GameRegistry, slug}}
  end
end
