defmodule JahnsWeb.GameLive do
  use JahnsWeb, :live_view

  alias Jahns.GameServer
  alias Jahns.GameSupervisor

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
    <%= if @game.state == :setup and is_nil(@player) do %>
      <button phx-click="join-game" class="p-2 mb-4 border border-1 border-black">
        join game
      </button>
    <% end %>

    <p>
      <%= case @game.state do %>
        <% :setup -> %>
          waiting for another player to join...
        <% :active -> %>
          active
        <% :finished -> %>
          finished
      <% end %>
    </p>

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
      {:ok, player} ->
        socket
        |> assign(player: player)

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
    {:ok, redirect(socket, to: "/setup?return_to=/game/#{slug}")}
  end

  defp put_temporary_flash(socket, level, message) do
    :timer.send_after(:timer.seconds(3), {:clear_flash, level})

    put_flash(socket, level, message)
  end
end
