defmodule ExBanking.Users do
  use GenServer
  alias ExBanking.Accounts

  def start_link(username) do
    GenServer.start_link(__MODULE__, [], name: via(username))
  end

  def get_balance(username, currency) do
    GenServer.call(via(username), {:get_balance, currency})
  end

  def deposit(username, amount, currency) do
    GenServer.call(via(username), {:deposit, amount, currency})
  end

  def withdraw(username, amount, currency) do
    GenServer.call(via(username), {:withdraw, amount, currency})
  end

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
    {:reply, new_balance, new_accounts}
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

  # def whereis_name(username) do
  #   Registry.whereis_name(via(username))
  # end

  def via(username) do
    String.to_atom(username)
    # {:via, __MODULE__, username}
  end
end
