defmodule JahnsWeb.LobbyLive do
  use JahnsWeb, :live_view

  alias Jahns.GameServer

  # TODO put into shared helpers dir
  def render(assigns) do
    ~H"""
    <div class="flex items-center flex-col gap-6">
      <.button phx-click="create-game">create new game</.button>

      <p>or</p>

      <form phx-change="update" phx-submit="join-game" phx-debounce="500" class="flex flex-col gap-2">
        <label>
          join existing game by slug: <.input name="slug" type="text" value={@slug} />
        </label>
        <.button type="submit">join</.button>
      </form>

      <%= if @error do %>
        <p class="text-center text-red-500"><%= @error %></p>
      <% end %>
    </div>
    """
  end

  def handle_event("create-game", _fields, socket) do
    slug = MnemonicSlugs.generate_slug()
    {:noreply, push_navigate(socket, to: ~p"/game/#{slug}")}
  end

  def handle_event("update", fields, socket) do
    %{"slug" => slug} = fields
    {:noreply, assign(socket, slug: slug)}
  end

  def handle_event("join-game", fields, socket) do
    %{"slug" => slug} = fields

    if GameServer.game_exists?(slug) do
      {:noreply, push_navigate(socket, to: ~p"/game/#{slug}?join")}
    else
      {:noreply, assign(socket, error: "#{slug}: game not found")}
    end
  end

  def mount(_params, %{"session_id" => _session_id}, socket) do
    {:ok, assign(socket, slug: "", error: nil)}
  end

  def mount(_params, _session, socket) do
    {:ok, redirect(socket, to: "/setup?return_to=/")}
  end
end
