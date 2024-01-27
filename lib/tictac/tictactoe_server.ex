defmodule Tictac.TictactoeServer do
  use GenServer

  require Logger

  alias Tictac.Tictactoe

  def add_player(slug, player_id, player_name) do
    with {:ok, player, game} <- call_by_slug(slug, {:add_player, player_id, player_name}) do
      broadcast_game_updated!(slug, game)
      {:ok, player}
    end
  end

  def cell_interact(slug, player_id, row_index, cell_index) do
    with {:ok, game} <- call_by_slug(slug, {:cell_interact, player_id, row_index, cell_index}) do
      broadcast_game_updated!(slug, game)
      {:ok, game}
    end
  end

  def get_game(slug) do
    call_by_slug(slug, :get_game)
  end

  def get_game_state(slug) do
    call_by_slug(slug, :get_game_state)
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
    {:ok, %{game: Tictactoe.new(slug)}}
  end

  @impl GenServer
  def handle_call({:add_player, player_id, player_name}, _from, state) do
    case Tictactoe.add_player(state.game, player_id, player_name) do
      {:ok, player, game} ->
        {:reply, {:ok, player, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call({:cell_interact, player_id, row_index, cell_index}, _from, state) do
    case Tictactoe.cell_interact(state.game, player_id, row_index, cell_index) do
      {:ok, game} ->
        {:reply, {:ok, game}, %{state | game: game}}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end

  @impl GenServer
  def handle_call(:get_game, _from, state) do
    {:reply, {:ok, state.game}, state}
  end

  @impl GenServer
  def handle_call(:get_game_state, _from, state) do
    {:reply, {:ok, state.game.state}, state}
  end

  @impl GenServer
  def handle_call({:get_player_by_id, player_id}, _from, state) do
    {:reply, Tictactoe.get_player_by_id(state.game, player_id), state}
  end

  defp broadcast_game_updated!(slug, game) do
    broadcast!(slug, :game_updated, %{game: game})
  end

  def broadcast!(slug, event, payload \\ %{}) do
    Phoenix.PubSub.broadcast!(Tictac.PubSub, slug, %{event: event, payload: payload})
  end

  defp via_tuple(slug) do
    {:via, Registry, {Tictac.TictactoeRegistry, slug}}
  end
end
