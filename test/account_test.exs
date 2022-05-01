defmodule ExBanking.AccountTest do
  use ExUnit.Case
  alias ExBanking.Account

  test "get_balance" do
    accounts = init()
    assert {:ok, 100} == Account.get_balance(accounts, "usd")
    assert {:error, :currency_not_exist} == Account.get_balance(accounts, "vnd")
  end

  test "increase_balance" do
    accounts = init()
    assert {:ok, 110} == Account.increase_balance(accounts, 10, "usd")
  end

  test "decrease_balance" do
    accounts = init()
    assert {:ok, 90} == Account.decrease_balance(accounts, 10, "usd")
    assert {:error, :not_enough_money} == Account.decrease_balance(accounts, 200, "usd")
  end

  defp init, do: [%Account{currency: "usd", balance: 100}]
end
