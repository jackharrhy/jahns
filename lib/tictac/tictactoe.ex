defmodule Tictac.Tictactoe do
  alias Tictac.TictactoePlayer

  @derive Jason.Encoder
  defstruct chat_messages: [],
            slug: nil,
            state: :setup,
            turn: nil,
            result: nil,
            board: [
              [nil, nil, nil],
              [nil, nil, nil],
              [nil, nil, nil]
            ],
            players: []

  def new(slug) do
    struct!(__MODULE__, slug: slug)
  end

  @doc """
  Sets the board of a game.
  Used for testing.
  """
  def set_board(game, board) do
    game |> Map.put(:board, board)
  end

  def start_game(game) do
    2 = length(game.players)

    random_mark = Enum.random(TictactoePlayer.marks())

    game
    |> Map.put(:state, :active)
    |> Map.put(:turn, random_mark)
  end

  def end_game(game, result) do
    game
    |> Map.put(:turn, nil)
    |> Map.put(:state, :finished)
    |> Map.put(:result, result)
  end

  def game_active(game) do
    if game.state == :active do
      :ok
    else
      {:error, :game_not_active}
    end
  end

  def it_is_my_turn(game, player) do
    if game.turn == player.mark do
      :ok
    else
      {:error, :not_your_turn}
    end
  end

  def cell_is_empty(game, row_index, cell_index) do
    cell = get_cell(game, row_index, cell_index)

    if cell == nil do
      :ok
    else
      {:error, :cell_not_empty}
    end
  end

  def get_cell(game, row_index, cell_index) do
    Enum.at(Enum.at(game.board, row_index), cell_index)
  end

  def result(game) do
    is_tie = Enum.all?(game.board, fn row -> Enum.all?(row, fn cell -> cell != nil end) end)

    if is_tie do
      :tie
    else
      board = game.board
      board_columns = Enum.zip(board) |> Enum.map(&Tuple.to_list/1)
      diag_1 = for i <- 0..2, do: Enum.at(Enum.at(board, i), i)
      diag_2 = for i <- 0..2, do: Enum.at(Enum.at(board, i), 2 - i)
      diagonals = [diag_1, diag_2]

      Enum.concat([board, board_columns, diagonals])
      |> Enum.find(fn
        [a, a, a] -> a
        _ -> nil
      end)
      |> case do
        nil -> nil
        winner -> {:winner, Enum.at(winner, 0)}
      end
    end
  end

  def set_cell(game, row_index, cell_index, value) do
    game
    |> Map.update!(:board, fn board ->
      board
      |> Enum.with_index()
      |> Enum.map(fn {row, row_index_} ->
        if row_index == row_index_ do
          row
          |> Enum.with_index()
          |> Enum.map(fn {cell, cell_index_} ->
            if cell_index == cell_index_ do
              value
            else
              cell
            end
          end)
        else
          row
        end
      end)
    end)
  end

  def next_turn(game) do
    case game.turn do
      "X" ->
        game |> Map.put(:turn, "O")

      "O" ->
        game |> Map.put(:turn, "X")
    end
  end

  def add_player(game, player_id, player_name) do
    case length(game.players) do
      0 ->
        player = TictactoePlayer.new(player_id, player_name)
        {:ok, player, Map.update!(game, :players, &[player | &1])}

      1 ->
        existing_player = hd(game.players)

        if existing_player.id == player_id do
          {:ok, existing_player, game}
        else
          if existing_player.name == player_name do
            {:error, :name_taken}
          else
            existing_mark = existing_player.mark

            mark =
              if existing_mark == "X" do
                "O"
              else
                "X"
              end

            player = TictactoePlayer.new(player_id, player_name, mark)

            game =
              game
              |> Map.update!(:players, &[player | &1])
              |> start_game()

            {:ok, player, game}
          end
        end

      _ ->
        {:error, :game_full}
    end
  end

  def cell_interact(game, player_id, row_index, cell_index) do
    with {:ok, player} <- get_player_by_id(game, player_id),
         :ok <- game_active(game),
         :ok <- it_is_my_turn(game, player),
         :ok <- cell_is_empty(game, row_index, cell_index) do
      game = game |> set_cell(row_index, cell_index, player.mark)

      game =
        case result(game) do
          nil ->
            game |> next_turn()

          result ->
            game |> end_game(result)
        end

      {:ok, game}
    end
  end

  def mark_to_player(game, mark) do
    Enum.find(game.players, fn player -> player.mark == mark end)
  end

  def current_player(game) do
    mark_to_player(game, game.turn)
  end

  def get_player_by_id(game, player_id) do
    player = Enum.find(game.players, fn player -> player.id == player_id end)

    if player do
      {:ok, player}
    else
      {:error, :player_not_found}
    end
  end
end
