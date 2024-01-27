defmodule Tictac.TictactoePlayer do
  defstruct [
    :id,
    :name,
    :mark
  ]

  @marks [
    "X",
    "O"
  ]

  def marks do
    @marks
  end

  def new(id, name, mark) do
    struct!(__MODULE__, %{
      id: id,
      name: name,
      mark: mark
    })
  end

  def new(id, name) do
    random_mark = Enum.random(@marks)
    new(id, name, random_mark)
  end
end

defimpl String.Chars, for: Tictac.TictactoePlayer do
  def to_string(player) do
    "#{player.name} (#{player.mark})"
  end
end
