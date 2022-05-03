defmodule ExBanking.ExBankingTest do
  use ExUnit.Case

  @usd "usd"

  describe "error create_user/1" do
    test "wrong_arguments" do
      assert {:error, :wrong_arguments} = ExBanking.create_user(:user_a)
    end

    test "exist" do
      user = Faker.Person.name()
      assert :ok = ExBanking.create_user(user)
      assert {:error, :user_already_exists} = ExBanking.create_user(user)
    end
  end

  describe "error deposit/2" do
    test "wrong_arguments" do
      assert {:error, :wrong_arguments} = ExBanking.deposit(:user_a, 10, "usd")
      assert {:error, :wrong_arguments} = ExBanking.deposit("user_a", :b, "usd")
      assert {:error, :wrong_arguments} = ExBanking.deposit("user_a", 10, :usd)
      assert {:error, :wrong_arguments} = ExBanking.deposit("user_a", -10, "usd")
    end

    test "user_does_not_exist" do
      assert {:error, :user_does_not_exist} = ExBanking.deposit("user_a", 10, "usd")
    end

    @tag :slow
    test "too_many_requests_to_user" do
      user = create_user()

      any_error? =
        for _ <- 1..10 do
          Task.async(fn ->
            :timer.sleep(:rand.uniform(10) * 100)
            ExBanking.deposit(user, 1, @usd)
          end)
        end
        |> Task.await_many(:infinity)
        |> Enum.member?({:error, :too_many_requests_to_user})

      assert any_error?
    end
  end

  describe "error withdraw/3" do
    test "wrong_arguments" do
      assert {:error, :wrong_arguments} = ExBanking.withdraw(:user_a, 10, "usd")
      assert {:error, :wrong_arguments} = ExBanking.withdraw("user_a", :b, "usd")
      assert {:error, :wrong_arguments} = ExBanking.withdraw("user_a", 10, :usd)
      assert {:error, :wrong_arguments} = ExBanking.withdraw("user_a", -10, "usd")
    end

    test "user_does_not_exist" do
      assert {:error, :user_does_not_exist} = ExBanking.withdraw("user_a", 10, "usd")
    end

    test "not_enough_money" do
      user_a = create_user()
      assert {:error, :not_enough_money} = ExBanking.withdraw(user_a, 10, "usd")
    end

    @tag :slow
    test "too_many_requests_to_user" do
      user = create_user()
      assert {:ok, 100.0} = ExBanking.deposit(user, 100, @usd)

      any_error? =
        for _ <- 1..10 do
          Task.async(fn ->
            :timer.sleep(:rand.uniform(10) * 100)
            ExBanking.withdraw(user, 1, @usd)
          end)
        end
        |> Task.await_many(:infinity)
        |> Enum.member?({:error, :too_many_requests_to_user})

      assert any_error?
    end
  end

  describe "error get_balance/2" do
    test "wrong_arguments" do
      assert {:error, :wrong_arguments} = ExBanking.get_balance(:user_a, "usd")
      assert {:error, :wrong_arguments} = ExBanking.get_balance("user_a", :usd)
    end

    test "user_does_not_exist" do
      assert {:error, :user_does_not_exist} = ExBanking.get_balance("user_a", "usd")
    end

    @tag :slow
    test "too_many_requests_to_user" do
      user = create_user()

      any_error? =
        for _ <- 1..10 do
          Task.async(fn ->
            :timer.sleep(:rand.uniform(10) * 100)
            ExBanking.get_balance(user, @usd)
          end)
        end
        |> Task.await_many(:infinity)
        |> Enum.member?({:error, :too_many_requests_to_user})

      assert any_error?
    end
  end

  describe "error send/4" do
    test "wrong_arguments" do
      assert {:error, :wrong_arguments} = ExBanking.send(:user_a, "user_b", 10, "usd")
      assert {:error, :wrong_arguments} = ExBanking.send("user_a", :user_b, 10, "usd")

      user_a = create_user()
      user_b = create_user()
      assert {:error, :wrong_arguments} = ExBanking.send(user_a, user_b, :b, "usd")
      assert {:error, :wrong_arguments} = ExBanking.send(user_a, user_b, 10, :usd)
      assert {:error, :wrong_arguments} = ExBanking.send(user_a, user_b, -10, "usd")
    end

    test "sender_does_not_exist" do
      assert {:error, :sender_does_not_exist} = ExBanking.send("user_a", "user_b", 10, "usd")
    end

    test "receiver_does_not_exist" do
      user_a = create_user()
      assert {:error, :receiver_does_not_exist} = ExBanking.send(user_a, "user_b", 10, "usd")
    end

    test "not_enough_money" do
      user_a = create_user()
      user_b = create_user()
      assert {:error, :not_enough_money} = ExBanking.send(user_a, user_b, 10, "usd")
    end

    @tag :slow
    test "too_many_requests_to_sender" do
      sender = create_user()
      ExBanking.deposit(sender, 100, @usd)

      any_error? =
        for _ <- 1..10 do
          receiver = create_user()

          Task.async(fn ->
            :timer.sleep(:rand.uniform(10) * 100)
            ExBanking.send(sender, receiver, 1, @usd)
          end)
        end
        |> Task.await_many(:infinity)
        |> Enum.member?({:error, :too_many_requests_to_sender})

      assert any_error?
    end

    @tag :slow
    test "too_many_requests_to_receiver" do
      receiver = create_user()

      senders =
        for _ <- 1..10 do
          sender = create_user()
          ExBanking.deposit(sender, 100, @usd)
          sender
        end

      any_error? =
        for i <- 1..10 do
          sender = Enum.at(senders, i - 1)

          Task.async(fn ->
            :timer.sleep(:rand.uniform(10) * 100)
            ExBanking.send(sender, receiver, 1, @usd)
          end)
        end
        |> Task.await_many(:infinity)
        |> Enum.member?({:error, :too_many_requests_to_receiver})

      assert any_error?
    end
  end

  @tag :slow
  test "Basic functions" do
    user_a = create_user()

    assert {:ok, 0} = ExBanking.get_balance(user_a, @usd)
    assert {:ok, 10.0} = ExBanking.deposit(user_a, 10, @usd)
    assert {:ok, 10.0} = ExBanking.get_balance(user_a, @usd)
    assert {:ok, 5.0} = ExBanking.withdraw(user_a, 5, @usd)
    assert {:ok, 3.66} = ExBanking.withdraw(user_a, 1.34, @usd)

    user_b = create_user()
    assert {:ok, 3.55, 0.11} = ExBanking.send(user_a, user_b, 0.11, @usd)
  end

  defp create_user do
    user = Faker.Person.name()
    assert :ok = ExBanking.create_user(user)
    user
  end
end
