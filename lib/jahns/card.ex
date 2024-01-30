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
    id = 1

    # movement cards

    metrobus_card = new(id, "Metrobus", {:text, "🚌"}, :move, 0, 4, 1)

    id = id + 1
    jiffy_card = new(id, "Jiffy", {:text, "🚕"}, :move, 2, 7, 2)

    id = id + 1
    newfound_card = new(id, "Newfound Cab", {:text, "🚕"}, :move, 3, 6, 2)

    id = id + 1
    mums_car = new(id, "Mum's Car", {:text, "🚗"}, :move, 6, 8, 3)

    id = id + 1
    cbs_taxi = new(id, "CB's Taxi", {:text, "🚕"}, :move, 8, 10, 4)

    id = id + 1
    aaron_mobile = new(id, "Aaron Mobile", {:text, "🚗"}, :move, 0, 8, 2)

    id = id + 1
    andrew_vehicle = new(id, "Andrew Vehicle", {:text, "🚗"}, :move, 2, 6, 2)

    # junk movement cards

    id = id + 1
    newfie_bullet = new(id, "Newfie Bullet", {:text, "🚄"}, :move, 0, 0, 0)

    [
      metrobus_card,
      jiffy_card,
      newfound_card,
      mums_car,
      cbs_taxi,
      aaron_mobile,
      andrew_vehicle,
      newfie_bullet
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
