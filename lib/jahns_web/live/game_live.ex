defmodule JahnsWeb.GameLive do
  use JahnsWeb, :live_view

  alias Jahns.Game
  alias Jahns.GameServer
  alias Jahns.GameSupervisor

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    {:ok, player} = Game.get_player_by_id(game, socket.assigns.session_id)

    {:noreply, assign(socket, game: game, player: player)}
  end

  def handle_info({:clear_flash, level}, socket) do
    {:noreply, clear_flash(socket, Atom.to_string(level))}
  end

  def handle_info({:put_temporary_flash, level, message}, socket) do
    {:noreply, put_temporary_flash(socket, level, message)}
  end

  def render_map(assigns) do
    ~H"""
    <svg viewBox="0 0 256 256" class="h-full">
      <%= for {node, x, y} <- @game.map.nodes do %>
        <circle id={node} cx={x} cy={y} r="5" fill="black" />
      <% end %>
      <%= for {{start_node, start_x, start_y}, {end_node, end_x, end_y}} <- @game.map.edges do %>
        <line
          id={"#{start_node}-#{end_node}"}
          x1={start_x}
          y1={start_y}
          x2={end_x}
          y2={end_y}
          stroke="black"
          stroke-width="2"
        />
      <% end %>
    </svg>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="game-container h-full w-full">
      <div class="map border flex items-center justify-center">
        <%= render_map(assigns) %>
      </div>
      <div class="messages border p-2 overflow-y-auto">
        <%= for message <- @game.messages do %>
          <p><%= message %></p>
        <% end %>
      </div>
      <div class="actions border flex items-center justify-center">
        <%= if @game.state == :setup and not is_nil(@player) and Game.player_can_start_game?(@game, @player) do %>
          <button phx-click="start-game" class="p-2 mb-4 border border-1 border-black">
            start game
          </button>
        <% end %>
      </div>
      <div class="info border flex flex-col items-center justify-center p-6 gap-4">
        <%= if @game.state == :setup and is_nil(@player) do %>
          <button phx-click="join-game" class="p-2 mb-4 border border-1 border-black">
            join game
          </button>
        <% end %>
        <%= unless is_nil(@player) do %>
          <p><%= @player.name %> <%= @player.art |> elem(1) %></p>
          <div class="flex text-xl gap-6">
            <p><%= @player.energy %> ⚡️</p>
            <p><%= @player.currency %> 🪙</p>
            <p><%= @player.points %> 💎</p>
          </div>
        <% end %>
      </div>
      <div class="cards border">
        <%= unless is_nil(@player) do %>
          <div class="flex h-full p-2 gap-2 justify-center">
            <%= for card <- @player.hand do %>
              <div class="flex flex-col gap-1 justify-center p-.25 h-full w-24 border-2 border text-center">
                <p class="text-xs"><%= card.name %></p>
                <p class="text-2xl"><%= card.art |> elem(1) %></p>
                <p><%= card.low_value %> - <%= card.high_value %></p>
                <p><%= card.cost %> ✨</p>
              </div>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>

    <%= if @debug do %>
      <div class="bg-black text-white p-4 mb-2">
        <p>player</p>
        <code><pre><%= Jason.encode!(@player, pretty: true) %></pre></code>
        <p>game</p>
        <code><pre><%= Jason.encode!(@game, pretty: true) %></pre></code>
      </div>
    <% end %>
    """
  end

  def handle_event("join-game", _, socket) do
    %{player: nil} = socket.assigns

    {:noreply, add_self_to_game(socket)}
  end

  def add_self_to_game(socket) do
    %{game: game, session_id: session_id} = socket.assigns
    player_name = MnemonicSlugs.generate_slug()

    case GameServer.add_player(game.slug, session_id, player_name) do
      {:ok, game, player} ->
        socket
        |> assign(game: game, player: player)

      {:error, reason} ->
        socket
        |> put_temporary_flash(:error, "#{reason}")
    end
  end

  def mount(%{"slug" => slug} = params, %{"session_id" => session_id}, socket) do
    debug = Map.has_key?(params, "debug")

    socket = assign(socket, debug: debug)

    socket = assign(socket, session_id: session_id)

    auto_join = Map.has_key?(params, "join")

    unless GameServer.game_exists?(slug) do
      GameSupervisor.start_game(slug)
    end

    {:ok, game} = GameServer.get_game(slug)

    socket = assign(socket, game: game)

    socket =
      case GameServer.get_player_by_id(slug, session_id) do
        {:ok, player} ->
          assign(socket, player: player)

        {:error, _reason} ->
          assign(socket, player: nil)
      end

    socket =
      if connected?(socket) do
        :ok = Phoenix.PubSub.subscribe(Jahns.PubSub, slug)

        if is_nil(socket.assigns.player) && (length(game.players) == 0 || auto_join) do
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
    {:ok, redirect(socket, to: "/setup?return_to=/game/#{slug}")}
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
