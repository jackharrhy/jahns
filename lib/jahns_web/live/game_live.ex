defmodule JahnsWeb.GameLive do
  use JahnsWeb, :live_view

  alias Jahns.Game
  alias Jahns.GameServer
  alias Jahns.GameSupervisor

  def handle_info(%{event: :game_updated, payload: %{game: game}}, socket) do
    socket = assign(socket, game: game)

    session_id = socket.assigns.session_id

    socket =
      case Game.get_player_by_id(game, session_id) do
        {:ok, player} ->
          assign(socket, player: player)

        {:error, _reason} ->
          assign(socket, player: nil)
      end

    {:noreply, socket}
  end

  def handle_info({:clear_flash, level}, socket) do
    {:noreply, clear_flash(socket, Atom.to_string(level))}
  end

  def handle_info({:put_temporary_flash, level, message}, socket) do
    {:noreply, put_temporary_flash(socket, level, message)}
  end

  def render_messages(assigns) do
    ~H"""
    <div class="messages border p-2 overflow-y-auto">
      <%= for message <- @game.messages do %>
        <p><%= message %></p>
        <hr class="my-1" />
      <% end %>
    </div>
    """
  end

  def render_actions(assigns) do
    ~H"""
    <div class="actions border flex items-center justify-center">
      <%= unless is_nil(@player) do %>
        <%= if Game.player_can_start_game?(@game, @player) do %>
          <button phx-click="start-game" class="p-2 mb-4 border border-1 border-black">
            start game
          </button>
        <% end %>
        <%= if Game.can_end_turn?(@game, @player) do %>
          <button phx-click="end-turn" class="p-2 mb-4 border border-1 border-black">
            end turn
          </button>
        <% end %>
      <% end %>
    </div>
    """
  end

  def render_player_info(assigns) do
    ~H"""
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
    """
  end

  def style_transform(transform, time \\ "0.25s", easing \\ "ease-in-out") do
    "transition: #{time} #{easing}; transform: #{transform};"
  end

  def player_to_style(player) do
    {_id, x, y} = player.node
    offset_amount = 16

    {x, y} =
      case player.index do
        0 -> {x, y - offset_amount}
        1 -> {x + offset_amount, y}
        2 -> {x, y + offset_amount}
        3 -> {x - offset_amount, y}
      end

    style_transform("translate(#{x}px, #{y}px)")
  end

  def render_map(assigns) do
    ~H"""
    <div class="map border flex items-center justify-center">
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
            stroke="rgba(0, 0, 0, 0.3)"
            stroke-width="2"
          />
        <% end %>
        <%= for %{id: id, art: {:text, text}} = player <- @game.players do %>
          <text
            id={id}
            dominant-baseline="middle"
            text-anchor="middle"
            style={player_to_style(player)}
          >
            <%= text %>
          </text>
        <% end %>
      </svg>
    </div>
    """
  end

  attr :card, :map, required: true
  attr :index, :integer, required: true
  attr :class, :string, required: true
  attr :style, :string, required: true

  def render_card(assigns) do
    ~H"""
    <button
      phx-click="use-card"
      phx-value-card-id={@card.id}
      class={"#{@class} card bg-white flex flex-col gap-1 justify-center items-center p-.25 border-2 border text-center"}
      style={@style}
    >
      <p class="text-xs"><%= @card.name %></p>
      <p class="text-2xl"><%= @card.art |> elem(1) %></p>
      <p><%= @card.low_value %> - <%= @card.high_value %></p>
      <p><%= @card.cost %> ✨</p>
    </button>
    <!--
    TODO
    <div
      class={"#{@class} card bg-white flex flex-col gap-1 justify-center items-center p-.25 border-2 border text-center"}
    >
      <p>jahns</p>
    </div>
    !--->
    """
  end

  def card_style(index, position) do
    transform =
      case position do
        :draw_pile ->
          "rotate3d(0, 1, 0, 180deg) translateX(calc((#{index} * var(--card-width) / 16) * -1))"

        :hand ->
          "rotate3d(0, 1, 0, 0deg) translateX(calc(#{index} * var(--card-width)))"

        :discard_pile ->
          "rotate3d(0, 1, 0, -180deg) translateX(calc(#{index} * var(--card-width) / 16))"
      end

    style_transform(transform, "1s", "ease-out")
  end

  def render_cards(assigns) do
    ~H"""
    <div class="cards flex border">
      <%= unless is_nil(@player) do %>
        <%= for {card, index} <- Enum.with_index(@player.draw_pile) do %>
          <.render_card
            card={card}
            index={index}
            class="draw-pile"
            style={card_style(index, :draw_pile)}
          />
        <% end %>
        <%= for {card, index} <- Enum.with_index(@player.hand) do %>
          <.render_card card={card} index={index} class="hand" style={card_style(index, :hand)} />
        <% end %>
        <%= for {card, index} <- Enum.with_index(@player.discard_pile) do %>
          <.render_card
            card={card}
            index={index}
            class="discard-pile"
            style={card_style(index, :discard_pile)}
          />
        <% end %>
      <% end %>
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="game-container h-full w-full">
      <%= render_messages(assigns) %>
      <%= render_actions(assigns) %>
      <%= render_player_info(assigns) %>

      <%= render_map(assigns) %>
      <%= render_cards(assigns) %>
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

  def handle_event("use-card", %{"card-id" => card_id}, socket) do
    %{player: player, game: game} = socket.assigns

    card_id = String.to_integer(card_id)

    case GameServer.attempt_to_use_card(game.slug, player.id, card_id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
  end

  def handle_event("join-game", _, socket) do
    %{player: nil} = socket.assigns

    {:noreply, add_self_to_game(socket)}
  end

  def handle_event("start-game", _, socket) do
    %{player: player, game: game} = socket.assigns

    case GameServer.start_game(game.slug, player.id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
  end

  def handle_event("end-turn", _, socket) do
    %{player: player, game: game} = socket.assigns

    case GameServer.attempt_to_end_turn(game.slug, player.id) do
      {:ok, game} ->
        {:noreply, assign(socket, game: game)}

      {:error, reason} ->
        {:noreply, put_temporary_flash(socket, :error, "#{reason}")}
    end
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
