defmodule ExBanking.PoolTest do
  use ExUnit.Case
  alias ExBanking.Pool

  @user "Alice"

  test ":ok" do
    Pool.start_link()
    assert Pool.value(@user) == 10
    assert :ok = Pool.can_query?(@user)

    assert :ok = Pool.decrement(@user)
    assert Pool.value(@user) == 9

    assert :ok = Pool.decrement(@user)
    assert Pool.value(@user) == 8

    assert :ok = Pool.increment(@user)
    assert Pool.value(@user) == 9
  end
end
