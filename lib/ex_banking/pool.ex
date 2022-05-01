defmodule ExBanking.Pool do
  use GenServer

  @max_conn 5
  def start_link(initial_value \\ %{}) do
    IO.inspect(binding(), label: "Pool start link")
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def can_query?(key, role \\ "user") do
    case value(key) do
      conn when conn > 0 -> :ok
      _ -> err(role)
    end
  end

  def value(key) do
    GenServer.call(__MODULE__, {:value, key})
  end

  def decrement(key) do
    GenServer.cast(__MODULE__, {:decrement, key})
  end

  def increment(key) do
    GenServer.cast(__MODULE__, {:increment, key})
  end

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call({:value, key}, _from, state) do
    value = Map.get(state, key, @max_conn)
    new_state = Map.put(state, key, value)
    {:reply, value, new_state}
  end

  @impl true
  def handle_cast({:decrement, key}, state) do
    new_state =
      Map.update(state, key, @max_conn - 1, fn
        conn when conn > 0 -> conn - 1
        conn -> conn
      end)

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:increment, key}, state) do
    new_state =
      Map.update(state, key, @max_conn, fn
        conn when conn < @max_conn -> conn + 1
        conn -> conn
      end)

    {:noreply, new_state}
  end

  defp err(user) do
    error = String.to_atom("too_many_requests_to_#{user}")
    {:error, error}
  end
end
