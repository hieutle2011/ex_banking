defmodule ExBanking.Account do
  defstruct currency: nil, balance: 0

  def get_balance(accounts, currency) when is_list(accounts) do
    case get_account(accounts, currency) do
      nil -> {:error, :currency_not_exist}
      %{} = account -> {:ok, Map.get(account, :balance)}
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

  defp get_account(accounts, currency) do
    Enum.find(accounts, &(&1.currency == currency))
  end

  defp mutate_balance(accounts, amount, currency, func) do
    with {:ok, balance} <- get_balance(accounts, currency) do
      func.(balance, amount)
    end
  end
end
