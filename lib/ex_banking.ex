defmodule ExBanking do
  @moduledoc """
  Documentation for `ExBanking`.
  """

  alias ExBanking.Users

  # todo user_already_exists
  @spec create_user(user :: String.t()) :: :ok | {:error, :wrong_arguments | :user_already_exists}
  def create_user(user) when is_binary(user) do
    Users.start_link(user)
    :ok
  end

  def create_user(_) do
    {:error, :wrong_arguments}
  end

  @spec deposit(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def deposit(user, amount, currency)
      when is_binary(user) and amount >= 0 and is_binary(currency) do
    Users.deposit(user, amount, currency)
  end

  def deposit(_, _, _) do
    {:error, :wrong_arguments}
  end

  @spec withdraw(user :: String.t(), amount :: number, currency :: String.t()) ::
          {:ok, new_balance :: number}
          | {:error,
             :wrong_arguments
             | :user_does_not_exist
             | :not_enough_money
             | :too_many_requests_to_user}
  def withdraw(user, amount, currency)
      when is_binary(user) and amount >= 0 and is_binary(currency) do
    Users.withdraw(user, amount, currency)
  end

  def withdraw(_, _, _) do
    {:error, :wrong_arguments}
  end

  @spec get_balance(user :: String.t(), currency :: String.t()) ::
          {:ok, balance :: number}
          | {:error, :wrong_arguments | :user_does_not_exist | :too_many_requests_to_user}
  def get_balance(user, currency) when is_binary(user) and is_binary(currency) do
    Users.get_balance(user, currency)
  end

  def get_balance(_, _), do: {:error, :wrong_arguments}

  @spec send(
          from_user :: String.t(),
          to_user :: String.t(),
          amount :: number,
          currency :: String.t()
        ) ::
          {:ok, from_user_balance :: number, to_user_balance :: number}
          | {:error,
             :wrong_arguments
             | :not_enough_money
             | :sender_does_not_exist
             | :receiver_does_not_exist
             | :too_many_requests_to_sender
             | :too_many_requests_to_receiver}
  def send(from_user, to_user, amount, currency) do
    Users.send(from_user, to_user, amount, currency)
  end

  @doc """
  Hello world.

  ## Examples

      iex> ExBanking.hello()
      :world

  """
  def hello do
    :world
  end

  def wip do
    h1 = "h1"
    h2 = "h2"
    usd = "usd"
    ExBanking.create_user(h1)
    ExBanking.get_balance(h1, usd)
    ExBanking.deposit(h1, 40, usd)
    ExBanking.get_balance(h1, usd)

    ExBanking.withdraw(h1, 10, usd)
    ExBanking.create_user(h2)
  end
end
