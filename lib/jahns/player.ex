defmodule Jahns.Player do
  @derive Jason.Encoder
  defstruct [
    :id,
    :name,
  ]

  def new(id, name) do
    struct!(__MODULE__, %{
      id: id,
      name: name,
    })
  end
end

defimpl String.Chars, for: Jahns.Player do
  def to_string(player) do
    "#{player.name}"
  end
end
