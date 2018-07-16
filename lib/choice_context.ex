defmodule ChoiceContext do
  import Kernel, except: [&&: 2]

  defstruct [:mode, :choices, :function]

  use GenServer

  # API
  def start_link(timeout, %{} = choices, function) when function |> is_function(1) do
    __MODULE__ |> GenServer.start_link({timeout, choices, function}, name: __MODULE__)
  end

  def start(timeout, %{} = choices, function) when function |> is_function(1) do
    __MODULE__ |> GenServer.start({timeout, choices, function}, name: __MODULE__)
  end

  def accept(server \\ __MODULE__, choice) do
    server |> GenServer.call({:accept, choice})
  end

  # Callbacks
  def init({timeout, choices, function}) do
    self() |> Process.send_after(:timeout, timeout)
    {:ok, %__MODULE__{mode: :active, choices: choices, function: function}}
  end

  def handle_call({:accept, option}, _from, %__MODULE__{mode: :active, choices: choices, function: function} = state) do
    {options, counter} = parse_option(option)
    result =
      case counter do
        1 ->
          [choice] = options
          choice |> process_choice(function, choices) |> unwrap()
        n when n |> is_integer() and n > 1->
          {processed, not_processed} =
            options |> Stream.map(fn option ->
              option |> process_choice(function, choices)
            end) |> Enum.split_with(fn processing_result ->
              case processing_result do
                {:ok, _result} -> true
                {:invalid_option, _description} -> false
              end
            end)
          processed_result = processed |> Stream.map(& unwrap(&1)) |> Enum.join("\n")
          not_processed_result = with x <- not_processed |> Stream.map(& unwrap(&1)) |> Enum.join("\n"), do: x && (x <> "\n" <> valid_options_string(choices))
          (processed_result && (processed_result <> (not_processed_result && "\n"))) <> not_processed_result
      end
    {:stop, :normal, {:result, result}, state}
  end

  # def handle_call({:accept, _option}, _from, %__MODULE__{mode: :active, choices: choices} = state) do
  #   {:reply, {:reply, "Valid options are: *#{choices |> Map.keys() |> Enum.join(~S|, |)}*"}, state}
  # end

  def handle_call(_, _from, %__MODULE__{mode: :inactive} = state) do
    {:stop, :normal, {:reply, "Too late, the choice context has ended."}, state}
  end

  def handle_info(:timeout, state) do
    {:noreply, %{state|mode: :inactive}}
  end

  def parse_option(option) do
    option |> String.split(",", trim: true) |> Stream.map(& String.trim(&1))
      |> Enum.map_reduce(0, fn x, counter -> {x, counter + 1} end)
  end

  def choose_option(option, map) do
    case map do
      %{^option => choice} ->
        {:choice, choice}
      _ ->
        :invalid_option
    end
  end

  def process_choice(choice, function, choices) do
    case choice |> choose_option(choices) do
      {:choice, choice} ->
        {:ok, function.(choice)}
      :invalid_option ->
        {:invalid_option, "Option *#{choice}* is invalid."}
    end
  end

  def valid_options_string(choices) do
    "Valid options are: *#{choices |> Map.keys() |> Enum.join(~S|, |)}*."
  end

  def unwrap(processing_result) do
    case processing_result do
      {:ok, result} -> result
      {:invalid_option, description} -> description
    end
  end

  defp swallow(a, b) do
    case a do
      "" -> b
      _ -> Kernel.&&(a, b)
    end
  end

  defp a && b, do: swallow(a, b)
end
