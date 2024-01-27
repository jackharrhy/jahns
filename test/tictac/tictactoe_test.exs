defmodule TictacTest.Tictactoe do
  use ExUnit.Case

  alias TictacTest.Tictactoe
  alias Tictac.Tictactoe

  test "creates empty game correctly" do
    slug = "foo"
    game = Tictactoe.new(slug)

    assert game.slug == slug
    assert game.state == :setup
    assert game.result == nil
  end

  test "creates game with two players" do
    game = Tictactoe.new("foo")
    {:ok, _player, game} = Tictactoe.add_player(game, "jack")
    {:ok, _player, game} = Tictactoe.add_player(game, "riley")

    assert length(game.players) == 2
    assert game.state == :active
    assert game.turn != nil
  end

  test "can't create a game with more than two players" do
    game = Tictactoe.new("foo")
    {:ok, _player, game} = Tictactoe.add_player(game, "jack")
    {:ok, _player, game} = Tictactoe.add_player(game, "riley")
    {:error, reason} = Tictactoe.add_player(game, "dan")

    assert length(game.players) == 2
    assert reason == :game_full
  end

  defp move(game, row_index, cell_index) do
    {:ok, game} =
      Tictactoe.cell_interact(game, Tictactoe.current_player(game).name, row_index, cell_index)

    game
  end

  test "plays a game of tictactoe" do
    game = Tictactoe.new("foo")
    {:ok, _jack, game} = Tictactoe.add_player(game, "jack")
    {:ok, _riley, game} = Tictactoe.add_player(game, "riley")

    first_player = Tictactoe.current_player(game)

    game =
      game
      |> move(0, 0)
      |> move(1, 0)
      |> move(0, 1)
      |> move(1, 1)
      |> move(0, 2)

    assert game.result == {:winner, first_player.mark}
    assert game.state == :finished
    assert game.turn == nil
  end

  test "winner check notices no winner" do
    game = Tictactoe.new("foo")
    {:ok, jack, game} = Tictactoe.add_player(game, "jack")
    {:ok, riley, game} = Tictactoe.add_player(game, "riley")

    game =
      game
      |> Tictactoe.set_board([
        [jack.mark, riley.mark, nil],
        [nil, nil, nil],
        [nil, nil, nil]
      ])

    assert Tictactoe.result(game) == nil
  end

  test "winner check notices straight line winner" do
    game = Tictactoe.new("foo")
    {:ok, jack, game} = Tictactoe.add_player(game, "jack")
    {:ok, riley, game} = Tictactoe.add_player(game, "riley")

    game =
      game
      |> Tictactoe.set_board([
        [jack.mark, jack.mark, jack.mark],
        [riley.mark, riley.mark, nil],
        [nil, nil, nil]
      ])

    assert Tictactoe.result(game) == {:winner, jack.mark}

    game =
      game
      |> Tictactoe.set_board([
        [jack.mark, nil, riley.mark],
        [nil, jack.mark, riley.mark],
        [nil, nil, riley.mark]
      ])

    assert Tictactoe.result(game) == {:winner, riley.mark}

    game =
      game
      |> Tictactoe.set_board([
        [nil, nil, riley.mark],
        [jack.mark, jack.mark, jack.mark],
        [nil, nil, riley.mark]
      ])

    assert Tictactoe.result(game) == {:winner, jack.mark}
  end

  test "winner check notices diagonal winner" do
    game = Tictactoe.new("foo")
    {:ok, jack, game} = Tictactoe.add_player(game, "jack")
    {:ok, riley, game} = Tictactoe.add_player(game, "riley")

    game =
      game
      |> Tictactoe.set_board([
        [jack.mark, riley.mark, riley.mark],
        [riley.mark, jack.mark, nil],
        [nil, nil, jack.mark]
      ])

    assert Tictactoe.result(game) == {:winner, jack.mark}

    game =
      game
      |> Tictactoe.set_board([
        [riley.mark, riley.mark, jack.mark],
        [riley.mark, jack.mark, nil],
        [jack.mark, nil, nil]
      ])

    assert Tictactoe.result(game) == {:winner, jack.mark}
  end
end
