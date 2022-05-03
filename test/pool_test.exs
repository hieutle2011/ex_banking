defmodule ExBanking.PoolTest do
  use ExUnit.Case
  alias ExBanking.Pool

  @user "Alice"

  test ":ok" do
    Pool.start_link()
    assert Pool.value(@user) == 3
    assert :ok = Pool.can_query?(@user)

    assert :ok = Pool.decrement(@user)
    assert Pool.value(@user) == 2

    assert :ok = Pool.decrement(@user)
    assert Pool.value(@user) == 1

    assert :ok = Pool.increment(@user)
    assert Pool.value(@user) == 2
  end
end
