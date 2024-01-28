defmodule Jahns.Player do
  alias Jahns.Card

  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :energy,
    :currency,
    :points,
    :draw_pile,
    :hand,
    :discard_pile
  ]

  @art [
    {:text, "👮"},
    {:text, "👷"},
    {:text, "👨‍🚒"},
    {:text, "🧑‍🔧"},
    {:text, "🧛"},
    {:text, "🧑‍🚀"},
    {:text, "🧙"},
    {:text, "🧚"},
    {:text, "🧑‍🌾"},
    {:text, "🐸"},
    {:text, "🐵"},
    {:text, "🐀"},
    {:text, "🪿"},
    {:text, "🐢"},
    {:text, "🐌"},
    {:text, "🐞"},
    {:text, "🐱"},
    {:text, "🐶"}
  ]

  @default_max_energy 5

  def default_max_energy() do
    @default_max_energy
  end

  def new(id, name) do
    random_art = Enum.random(@art)

    struct!(__MODULE__, %{
      id: id,
      name: name,
      art: random_art,
      energy: @default_max_energy,
      currency: 0,
      points: 0,
      draw_pile: [],
      hand: Card.cards(),
      discard_pile: []
    })
  end
end

defimpl String.Chars, for: Jahns.Player do
  def to_string(player) do
    "#{player.name}"
  end
end
