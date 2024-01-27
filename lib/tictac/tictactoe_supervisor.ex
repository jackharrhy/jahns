defmodule Tictac.TictactoeSupervisor do
  use DynamicSupervisor

  alias Tictac.TictactoeServer

  def start_link(_arg) do
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(nil) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_game(slug) do
    child_spec = %{
      id: TictactoeServer,
      start: {TictactoeServer, :start_link, [slug]},
      restart: :transient
    }

    DynamicSupervisor.start_child(__MODULE__, child_spec)
  end

  def stop_game(slug) do
    case Tictac.TictactoeServer.game_pid(slug) do
      pid when is_pid(pid) ->
        DynamicSupervisor.terminate_child(__MODULE__, pid)

      nil ->
        :ok
    end
  end
end
