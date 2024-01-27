defmodule Jahns.Repo do
  use Ecto.Repo,
    otp_app: :jahns,
    adapter: Ecto.Adapters.SQLite3
end
