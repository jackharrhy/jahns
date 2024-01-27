defmodule TictacWeb.TictactoeLive do
  use TictacWeb, :live_view

  alias Tictac.TictactoeServer
  alias Tictac.TictactoeSupervisor

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info({:clear_flash, level}, socket) do
    {:noreply, clear_flash(socket, Atom.to_string(level))}
  end

  def handle_info({:put_temporary_flash, level, message}, socket) do
    {:noreply, put_temporary_flash(socket, level, message)}
  end

  def render(assigns) do
    ~H"""
    <div class="w-full h-full flex items-center justify-center flex-col">
      <%= if @game.state == :setup and is_nil(@player) do %>
        <button phx-click="join-game" class="p-2 mb-4 border border-1 border-black">
          join game
        </button>
      <% end %>

      <%= if @game.state != :setup do %>
        <p>
          <%= Enum.at(@game.players, 0) |> to_string() %> vs. <%= Enum.at(@game.players, 1)
          |> to_string() %>
        </p>
      <% end %>

      <p>
        <%= case @game.state do %>
          <% :setup -> %>
            waiting for another player to join...
          <% :active -> %>
            <%= @game.turn %> to move
          <% :finished -> %>
            <%= case @game.result do %>
              <% :tie -> %>
                draw
              <% {:winner, mark} -> %>
                <%= mark %> won
            <% end %>
        <% end %>
      </p>

      <div class="p-4">
        <%= for {row, row_index} <- Enum.with_index(@game.board) do %>
          <div class="flex">
            <%= for {cell, cell_index} <- Enum.with_index(row) do %>
              <button
                phx-click="cell-click"
                phx-value-row-index={row_index}
                phx-value-cell-index={cell_index}
                class="flex text-3xl items-center justify-center w-16 h-16 border border-2 border-slate-300"
              >
                <%= cell %>
              </button>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def handle_event("join-game", _, socket) do
    %{player: nil} = socket.assigns

    {:noreply, add_self_to_game(socket)}
  end

  def handle_event("cell-click", %{"row-index" => row_index, "cell-index" => cell_index}, socket) do
    row_index = String.to_integer(row_index)
    cell_index = String.to_integer(cell_index)

    %{game: game, player: player} = socket.assigns

    if player == nil do
      {:noreply, put_temporary_flash(socket, :error, "not in the game")}
    else
      socket =
        case TictactoeServer.cell_interact(game.slug, player.id, row_index, cell_index) do
          {:ok, _game} ->
            socket

          {:error, error} ->
            # TODO map error atom -> user facing string
            socket
            |> put_temporary_flash(:error, "#{error}")
        end

      {:noreply, socket}
    end
  end

  def add_self_to_game(socket) do
    %{game: game, session_id: session_id} = socket.assigns
    player_name = MnemonicSlugs.generate_slug()

    case TictactoeServer.add_player(game.slug, session_id, player_name) do
      {:ok, player} ->
        socket
        |> assign(player: player)

      {:error, :game_full} ->
        socket
        |> put_temporary_flash(:error, "game full")
    end
  end

  def mount(%{"slug" => slug} = params, %{"session_id" => session_id}, socket) do
    socket = assign(socket, session_id: session_id)

    auto_join = Map.has_key?(params, "join")

    unless TictactoeServer.game_exists?(slug) do
      TictactoeSupervisor.start_game(slug)
    end

    {:ok, game} = TictactoeServer.get_game(slug)

    socket = assign(socket, game: game)

    socket =
      case TictactoeServer.get_player_by_id(slug, session_id) do
        {:ok, player} ->
          assign(socket, player: player)

        {:error, weird} ->
          assign(socket, player: nil)
      end

    socket =
      if connected?(socket) do
        :ok = Phoenix.PubSub.subscribe(Tictac.PubSub, slug)

        if !is_nil(socket.assigns.player) && (length(game.players) == 0 || auto_join) do
          add_self_to_game(socket)
        else
          socket
        end
      else
        socket
      end

    {:ok, socket}
  end

  def mount(%{"slug" => slug}, _session, socket) do
    {:ok, redirect(socket, to: "/setup?return_to=/tictactoe/#{slug}")}
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
