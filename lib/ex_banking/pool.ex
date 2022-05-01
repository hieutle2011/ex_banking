defmodule ExBanking.Pool do
  use Agent

  @max_conn 5
  def start_link(initial_value \\ %{}) do
    IO.inspect(binding(), label: "Pool start link")
    Agent.start_link(fn -> initial_value end, name: __MODULE__)
  end

  def can_query?(key, role \\ "user") do
    case value(key) do
      conn when conn > 0 -> :ok
      _ -> err(role)
    end
  end

  def value(key) do
    Agent.get(__MODULE__, & &1) |> Map.get(key, @max_conn)
  end

  def decrement(key) do
    Agent.update(__MODULE__, fn state ->
      Map.update(state, key, @max_conn - 1, fn
        conn when conn > 0 -> conn - 1
        conn -> conn
      end)
    end)
  end

  def increment(key) do
    Agent.update(__MODULE__, fn state ->
      Map.update(state, key, @max_conn, fn
        conn when conn < @max_conn -> conn + 1
        conn -> conn
      end)
    end)
  end

  defp err(user) do
    error = String.to_atom("too_many_requests_to_#{user}")
    {:error, error}
  end
end
