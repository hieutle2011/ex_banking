defmodule ExBanking.Users do
  use GenServer
  alias ExBanking.Accounts

  # # # # # # # #
  #  Client API #
  # # # # # # # #

  def start_link(username) do
    GenServer.start_link(__MODULE__, [], name: via(username))
  end

  def get_balance(username, currency) do
    GenServer.call(via(username), {:get_balance, currency})
  catch
    :exit, {:noproc, _} -> {:error, :user_does_not_exist}
  end

  def deposit(username, amount, currency) do
    GenServer.call(via(username), {:deposit, amount, currency})
  catch
    :exit, {:noproc, _} -> {:error, :user_does_not_exist}
  end

  def withdraw(username, amount, currency) do
    GenServer.call(via(username), {:withdraw, amount, currency})
  catch
    :exit, {:noproc, _} -> {:error, :user_does_not_exist}
  end

  def send(from_user, to_user, amount, currency) do
    with {:sender, {:ok, from_user_balance}} <- {:sender, withdraw(from_user, amount, currency)},
         {:receiver, {:ok, to_user_balance}} <- {:receiver, deposit(to_user, amount, currency)} do
      {:ok, from_user_balance, to_user_balance}
    else
      {:sender, {:error, :user_does_not_exist}} ->
        {:error, :sender_does_not_exist}

      {:sender, {:error, error}} ->
        {:error, error}

      {:receiver, {:error, :user_does_not_exist}} ->
        deposit(from_user, amount, currency)
        {:error, :receiver_does_not_exist}
    end
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

  def via(username) do
    String.to_atom(username)
    # {:via, __MODULE__, {ExBanking.Registry, username}}
  end
end
