defmodule Jahns.Card do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
    :art,
    :action,
    :low_value,
    :high_value,
    :cost
  ]

  def cards() do
    metrobus_card = new(1, "Metrobus", {:text, "🚌"}, :move, 0, 4, 1)
    jiffy_card = new(2, "Jiffy", {:text, "🚕"}, :move, 2, 7, 2)
    newfound_card = new(3, "Newfound Cab", {:text, "🚕"}, :move, 3, 6, 2)

    [
      metrobus_card,
      jiffy_card,
      newfound_card
    ]
  end

  def new(id, name, art, action, low_value, high_value, cost) do
    struct!(__MODULE__, %{
      id: id,
      name: name,
      art: art,
      action: action,
      low_value: low_value,
      high_value: high_value,
      cost: cost
    })
  end
end
