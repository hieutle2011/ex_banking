defmodule ExBanking.Account do
  use Agent

  def open(username) do
    {:ok, pid} = Agent.start_link(fn -> %{} end, name: via(username))

    pid
  end

  def value(username) do
    Agent.get(username, & &1)
  end

  def via(username) do
    {:via, __MODULE__, username}
  end
end
