defmodule ChoiceContext do
  defstruct [:mode]

  use GenServer

  # API
  def start_link(timeout) do
    __MODULE__ |> GenServer.start_link(timeout, name: __MODULE__)
  end

  def accept(server \\ __MODULE__, choice) do
    server |> GenServer.call({:accept, choice})
  end

  # Callbacks
  def init(timeout) do
    self() |> Process.send_after(:timeout, timeout)
    {:ok, %__MODULE__{mode: :active}}
  end

  def handle_call({:accept, choice}, _from, %__MODULE__{mode: :active} = state) do
    {:stop, :normal, {:choice, choice}, state}
  end

  def handle_call(_, _from, %__MODULE__{mode: :inactive} = state) do
    {:stop, :normal, {:reply, "Too late, the choise context has ended."}, state}
  end

  def handle_info(:timeout, state) do
    {:noreply, %{state|mode: :inactive}}
  end
end
