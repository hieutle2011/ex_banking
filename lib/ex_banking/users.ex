defmodule ExBanking.Users do
  @moduledoc false
  use GenServer
  alias ExBanking.Accounts
  alias ExBanking.Pool

  # # # # # # # #
  #  Client API #
  # # # # # # # #

  def start_link(username) do
    GenServer.start_link(__MODULE__, [], name: via(username))
  end

  def get_balance(username, currency) do
    mfa = {GenServer, :call, [via(username), {:get_balance, currency}, timeout()]}
    do_lock(username, mfa)
  end

  def deposit(username, amount, currency) do
    mfa = {GenServer, :call, [via(username), {:deposit, amount, currency}, timeout()]}
    do_lock(username, mfa)
  end

  def withdraw(username, amount, currency) do
    mfa = {GenServer, :call, [via(username), {:withdraw, amount, currency}, timeout()]}
    do_lock(username, mfa)
  end

  def send(from_user, to_user, amount, currency) do
    mfa1 = {GenServer, :call, [via(from_user), {:withdraw, amount, currency}, timeout()]}
    mfa2 = {GenServer, :call, [via(to_user), {:deposit, amount, currency}, timeout()]}

    do_locks(from_user, to_user, mfa1, mfa2)
  end

  # # # # # # #
  #  Callback #
  # # # # # # #

  @impl true
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  def handle_call({:get_balance, currency}, _from, accounts) do
    balance = Accounts.get_balance(accounts, currency)
    {:reply, balance, accounts}
  end

  @impl true
  def handle_call({:deposit, amount, currency}, _from, accounts) do
    {new_balance, new_accounts} = Accounts.deposit(accounts, amount, currency)
    {:reply, {:ok, new_balance}, new_accounts}
  end

  @impl true
  def handle_call({:withdraw, amount, currency}, _from, accounts) do
    case Accounts.withdraw(accounts, amount, currency) do
      {:ok, new_balance, new_accounts} ->
        {:reply, {:ok, new_balance}, new_accounts}

      {:error, error} ->
        {:reply, {:error, error}, accounts}
    end
  end

  # # # # # # #
  #  Helpers  #
  # # # # # # #

  defp via(username) do
    String.to_atom(username)
    # {:via, __MODULE__, {ExBanking.Registry, username}}
  end

  defp do_lock(username, mfa) do
    case exists?(username) do
      {:ok, _} -> Pool.lock_user(username, mfa)
      {:error, error} -> {:error, error}
    end
  end

  defp do_locks(from_user, to_user, mfa1, mfa2) do
    with {:sender, {:ok, _}} <- {:sender, exists?(from_user)},
         {:receiver, {:ok, _}} <- {:receiver, exists?(to_user)} do
      Pool.lock_users(from_user, to_user, mfa1, mfa2)
    else
      {:sender, {:error, :user_does_not_exist}} -> err("sender")
      {:receiver, {:error, :user_does_not_exist}} -> err("receiver")
      any -> any
    end
  end

  defp exists?(username) do
    case Process.whereis(via(username)) do
      nil -> {:error, :user_does_not_exist}
      pid -> {:ok, pid}
    end
  end

  defp timeout do
    if Mix.env() == :test,
      do: 10_000,
      else: 5_000
  end

  defp err(role) do
    error = String.to_atom("#{role}_does_not_exist")
    {:error, error}
  end
end
