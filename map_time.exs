{:ok, raw_svg} = File.read("./assets/svg/example.svg")

{xmerl, _} = raw_svg |> :erlang.binary_to_list() |> :xmerl_scan.string()

xpath_query = "//circle"

for result <-
      :xmerl_xpath.string(:erlang.binary_to_list(xpath_query), xmerl) do
end
