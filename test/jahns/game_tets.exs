defmodule JahnsTest.Game do
  use ExUnit.Case

  alias Jahns.Game

  test "creates empty game correctly" do
    slug = "foo"
    game = Game.new(slug)

    assert game.slug == slug
    assert game.state == :setup
    assert game.result == nil
  end
end
