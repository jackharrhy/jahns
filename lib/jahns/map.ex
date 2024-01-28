defmodule Jahns.Map do
  @derive Jason.Encoder
  defstruct [
    :nodes,
    :edges
  ]

  def new() do
    this_file = __ENV__.file

    map_file =
      Path.dirname(this_file)
      |> Path.join("../data/map.json")
      |> Path.expand()

    raw_map = File.read!(map_file)

    %{"nodes" => nodes, "edges" => edges} = Jason.decode!(raw_map)

    nodes =
      for node <- nodes do
        %{"id" => id, "x" => x, "y" => y} = node
        id = String.to_atom(id)
        {id, x, y}
      end

    edges =
      for edge <- edges do
        %{"start" => start, "end" => end_} = edge

        %{"node" => node, "x" => x, "y" => y} = start
        node = String.to_atom(node)
        start = {node, x, y}

        %{"node" => node, "x" => x, "y" => y} = end_
        node = String.to_atom(node)
        end_ = {node, x, y}

        {start, end_}
      end

    struct!(__MODULE__, %{
      nodes: nodes,
      edges: edges
    })
  end
end
