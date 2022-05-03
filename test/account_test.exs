defmodule ExBanking.AccountsTest do
  use ExUnit.Case
  alias ExBanking.Accounts
  alias ExBanking.Account

  test "get_balance" do
    accounts = init()
    assert {:ok, 100} == Accounts.get_balance(accounts, "usd")
    assert {:ok, 0} == Accounts.get_balance(accounts, "vnd")
  end

  test "init" do
    assert %Account{currency: "usd", balance: 1.55} = Accounts.init("usd", 1.55)
  end

  defp init, do: [Accounts.init("usd", 100)]
end
