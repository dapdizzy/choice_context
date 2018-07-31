defmodule ChoiceContext do
  import Kernel, except: [&&: 2]

  defstruct [:mode, :choices, :timeout_action]

  use GenServer

  # API
  def start_link(timeout, %{} = choices, timeout_action \\ nil) do
    validate_timeout_action(timeout_action)
    __MODULE__ |> GenServer.start_link({timeout, choices, timeout_action}, name: __MODULE__)
  end

  def start(timeout, %{} = choices, timeout_action \\ nil) do
    validate_timeout_action(timeout_action)
    __MODULE__ |> GenServer.start({timeout, choices, timeout_action}, name: __MODULE__)
  end

  defp validate_timeout_action(nil), do: :ok

  defp validate_timeout_action(timeout_action) do
    unless timeout_action |> is_function(0) do
      raise "timeout_action should be a function/0"
    end
  end

  def accept(server \\ __MODULE__, choice) do
    server |> GenServer.call({:accept, choice})
  end

  # Callbacks
  def init({timeout, choices, timeout_action}) do
    self() |> Process.send_after(:timeout, timeout)
    {:ok, %__MODULE__{mode: :active, choices: choices, timeout_action: timeout_action}}
  end

  def handle_call({:accept, option}, _from, %__MODULE__{mode: :active, choices: choices} = state) do
    {options, counter} = parse_option(option)
    {stop, result} =
      case counter do
        1 ->
          [choice] = options
          choice |> choose_option(choices)
            |> case do
              {:choice, chosen_option} -> {true, %{selected_option: chosen_option}}
              {:invalid_option, invalid_option} -> {false, %{reply: (with x when x != "" <- invalid_option |> invalid_option_string(), do: x && (x <> "\n" <> valid_options_string(choices)))}}
            end
        n when n |> is_integer() and n > 1->
          {valid_options, invalid_options} =
            options |> Stream.map(fn option ->
              option |> choose_option(choices)
            end) |> Enum.split_with(fn choose_result ->
              case choose_result do
                {:choice, _valid_option} -> true
                {:invalid_option, _option} -> false
              end
            end)
          valid_options = valid_options |> Enum.map(& unwrap(&1))
          invalid_options_string =
            ((invalid_options |> Stream.map(& unwrap(&1) |> invalid_option_string()))
            |> Enum.join("\n")) &&& ("\n" <> valid_options_string(choices))
          # invalid_options_string = with x <- invalid_options |> Stream.map(& unwrap(&1) |> invalid_option_string()) |> Enum.join("\n"), do: x && (x <> "\n" <> valid_options_string(choices))
          {valid_options |> Enum.count() > 0, %{selected_options: valid_options, reply: invalid_options_string}}
      end
    reply = {:result, result}
    if stop do
      {:stop, :normal, reply, state}
    else
      {:reply, reply, state}
    end
  end

  # def handle_call({:accept, _option}, _from, %__MODULE__{mode: :active, choices: choices} = state) do
  #   {:reply, {:reply, "Valid options are: *#{choices |> Map.keys() |> Enum.join(~S|, |)}*"}, state}
  # end

  def handle_call(_, _from, %__MODULE__{mode: :inactive} = state) do
    {:stop, :normal, {:reply, "Too late, the choice context has ended."}, state}
  end

  def handle_info(:timeout, %__MODULE__{mode: mode, timeout_action: timeout_action} = state) do
    if mode == :active && timeout_action != nil do
      timeout_action.()
    end
    {:stop, :normal, %{state|mode: :inactive}}
  end

  def parse_option(option) when option |> is_binary() do
    option |> String.split(",", trim: true) |> Stream.map(& String.trim(&1))
      |> Enum.map_reduce(0, fn x, counter -> {x, counter + 1} end)
  end

  def parse_option(option), do: {[option], 1}

  def choose_option(option, map) do
    case map do
      %{^option => choice} ->
        {:choice, choice}
      _ ->
        {:invalid_option, option}
    end
  end

  defp invalid_option_string(option) do
    "Option *#{option}* is invalid."
  end

  def valid_options_string(choices) do
    "Valid options are: *#{choices |> Map.keys() |> Enum.join(~S|, |)}*."
  end

  def unwrap(choice) do
    case choice do
      {:choice, valid_choice} -> valid_choice
      {:invalid_option, invalid_choice} -> invalid_choice
    end
  end

  defp swallow(a, b) do
    case a do
      "" -> b
      _ -> Kernel.&&(a, b)
    end
  end

  defp if_concat(a, b) do
    if a && a != "", do: a <> b
  end

  defp a && b, do: swallow(a, b)

  defp a &&& b, do: if_concat(a, b)
end
