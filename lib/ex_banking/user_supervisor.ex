defmodule ExBanking.UsersSupervisor do
  use DynamicSupervisor

  def start_link(init_arg) do
    IO.puts("Starting user supervisor ...")
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  def start_child(name) do
    spec = %{id: ExBanking.Users, start: {ExBanking.Users, :start_link, [name]}}

    case DynamicSupervisor.start_child(__MODULE__, spec) do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> {:error, :user_already_exists}
    end
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
