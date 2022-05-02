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

  def lock_user(username, {m, f, a}) do
    with :ok <- can_query?(username),
         :ok <- decrement(username),
         {:ok, balance} <- apply(m, f, a),
         :ok <- increment(username) do
      {:ok, balance}
    end
  catch
    :exit, {:noproc, _} ->
      # todo
      # drop(username)
      {:error, :user_does_not_exist}
  end

  def lock_users(from_user, to_user, {m1, f1, a1}, {m2, f2, a2}, opts) do
    with :ok <- can_query?(from_user, "sender"),
         :ok <- can_query?(to_user, "receiver"),
         :ok <- decrement(from_user),
         :ok <- decrement(to_user),
         {:sender, {:ok, from_user_balance}} <- {:sender, apply(m1, f1, a1)},
         {:receiver, {:ok, to_user_balance}} <- {:receiver, apply(m2, f2, a2)},
         :ok <- increment(from_user),
         :ok <- increment(to_user) do
      {:ok, from_user_balance, to_user_balance}
    else
      {:sender, {:error, :user_does_not_exist}} ->
        :ok = increment(from_user)
        :ok = increment(to_user)
        {:error, :sender_does_not_exist}

      {:sender, {:error, error}} ->
        :ok = increment(from_user)
        :ok = increment(to_user)
        {:error, error}

      {:receiver, {:error, :user_does_not_exist}} ->
        {m, f, a} = Keyword.fetch!(opts, :revert_sender_mfa)
        apply(m, f, a)
        :ok = increment(from_user)
        :ok = increment(to_user)
        {:error, :receiver_does_not_exist}

      {:error, error} ->
        {:error, error}
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
    IO.inspect(value, label: "conn value:")
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

    IO.inspect(binding(), label: "decrement")

    {:noreply, new_state}
  end

  @impl true
  def handle_cast({:increment, key}, state) do
    new_state =
      Map.update(state, key, @max_conn, fn
        conn when conn < @max_conn -> conn + 1
        conn -> conn
      end)

    IO.inspect(binding(), label: "increment")

    {:noreply, new_state}
  end

  defp err(user) do
    error = String.to_atom("too_many_requests_to_#{user}")
    {:error, error}
  end
end
