defmodule ExBanking.Accounts do
  @moduledoc false
  alias ExBanking.Account

  def init(currency, balance) do
    %Account{currency: currency, balance: balance}
  end

  def deposit(accounts, amount, currency) do
    if Mix.env() == :test, do: :timer.sleep(:rand.uniform(10) * 100)

    case get_account(accounts, currency) do
      nil ->
        balance = float_round(amount)
        new_accounts = [init(currency, balance) | accounts]
        {balance, new_accounts}

      %Account{balance: balance} = _account ->
        new_balance = float_round(balance + amount)
        index = Enum.find_index(accounts, &(&1.currency == currency))
        new_accounts = List.update_at(accounts, index, &%{&1 | balance: new_balance})
        {new_balance, new_accounts}
    end
  end

  def withdraw(accounts, amount, currency) do
    if Mix.env() == :test, do: :timer.sleep(:rand.uniform(10) * 100)

    case get_account(accounts, currency) do
      nil ->
        {:error, :not_enough_money}

      %Account{balance: balance} = _account ->
        new_balance = float_round(balance - amount)

        if new_balance >= 0 do
          index = Enum.find_index(accounts, &(&1.currency == currency))
          new_accounts = List.update_at(accounts, index, &%{&1 | balance: new_balance})
          {:ok, new_balance, new_accounts}
        else
          {:error, :not_enough_money}
        end
    end
  end

  def get_balance(accounts, currency) when is_list(accounts) do
    if Mix.env() == :test, do: :timer.sleep(:rand.uniform(10) * 100)

    case get_account(accounts, currency) do
      nil -> {:ok, 0}
      %Account{} = account -> {:ok, Map.get(account, :balance)}
    end
  end

  def increase_balance(accounts, amount, currency) do
    balance = mutate_balance(accounts, amount, currency, &Kernel.+/2)
    {:ok, balance}
  end

  def decrease_balance(accounts, amount, currency) do
    case mutate_balance(accounts, amount, currency, &Kernel.-/2) do
      balance when balance < 0 -> {:error, :not_enough_money}
      balance -> {:ok, balance}
    end
  end

  # # # # # # #
  #  Helpers  #
  # # # # # # #

  defp get_account(accounts, currency) do
    Enum.find(accounts, &(&1.currency == currency))
  end

  defp mutate_balance(accounts, amount, currency, func) do
    with {:ok, balance} <- get_balance(accounts, currency) do
      func.(balance, amount)
    end
  end

  defp float_round(amount) when is_integer(amount), do: float_round(1.0 * amount)
  defp float_round(amount) when is_float(amount), do: Float.round(amount, 2)
end
