defmodule ExBanking.AccountsTest do
  use ExUnit.Case
  alias ExBanking.Accounts
  alias ExBanking.Account

  test "get_balance" do
    accounts = init()
    assert {:ok, 100} == Accounts.get_balance(accounts, "usd")
    assert {:ok, 0} == Accounts.get_balance(accounts, "vnd")
  end

  test "increase_balance" do
    accounts = init()
    assert {:ok, 110} == Accounts.increase_balance(accounts, 10, "usd")
  end

  test "decrease_balance" do
    accounts = init()
    assert {:ok, 98.45} == Accounts.decrease_balance(accounts, 1.55, "usd")
    assert {:error, :not_enough_money} == Accounts.decrease_balance(accounts, 200, "usd")
  end

  test "init" do
    assert %Account{currency: "usd", balance: 1.55} = Accounts.init("usd", 1.55)
  end

  defp init, do: [Accounts.init("usd", 100)]
end
