defmodule ExBanking.Pool do
  @moduledoc false
  use GenServer

  @max_conn 5

  # # # # # # # #
  #  Client API #
  # # # # # # # #

  def start_link(initial_value \\ %{}) do
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  def can_query?(key, role \\ "user") do
    case value(key) do
      conn when conn > 0 -> :ok
      _ -> err(role)
    end
  end

  def lock_user(username, {m, f, a}) do
    with :ok <- can_query?(username),
         :ok <- decrement(username),
         {:ok, balance} <- apply(m, f, a),
         :ok <- increment(username) do
      {:ok, balance}
    end
  end

  def lock_users(from_user, to_user, {m1, f1, a1}, {m2, f2, a2}) do
    with :ok <- can_query?(from_user, "sender"),
         :ok <- can_query?(to_user, "receiver"),
         # sender
         :ok <- decrement(from_user),
         {:sender, {:ok, from_user_balance}} <- {:sender, apply(m1, f1, a1)},
         :ok <- increment(from_user),
         # receiver
         :ok <- decrement(to_user),
         {:receiver, {:ok, to_user_balance}} <- {:receiver, apply(m2, f2, a2)},
         :ok <- increment(to_user) do
      {:ok, from_user_balance, to_user_balance}
    else
      {:sender, {:error, :not_enough_money}} ->
        :ok = increment(from_user)
        {:error, :not_enough_money}

      any ->
        any
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

  # # # # # # #
  #  Callback #
  # # # # # # #

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

  # # # # # # #
  #  Helpers  #
  # # # # # # #

  defp err(user) do
    error = String.to_atom("too_many_requests_to_#{user}")
    {:error, error}
  end
end
