defmodule Expeg do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro rule(name, do: derivation) do
    quote do
      def unquote(name)(input, index) do
        unquote(derivation).(input, index)
      end
    end
  end

  defmacro rule(name, transformation, do: derivation) do
    quote do
      def unquote(name)(input, index) do
        unquote(transformation)(unquote(derivation).(input, index))
      end
    end
  end

  defmacro transform(name, do: derivation) do
    quote do
      def unquote(name)({:fail, index}) do
        {:fail, index}
      end
      def unquote(name)({result, rest, index}) do
        {unquote(derivation).(result), rest, index}
      end
    end
  end

  defmacro root(name) do
    quote do
      def parse(input) do
        case unquote(name)(input, 0) do
          {ast, "", index} -> ast
          {:fail, 0} -> {:fail, 0}
          res -> {:fail, res}
        end
      end
    end
  end

  def string(s) do
    fn (input, index) ->
      case String.starts_with?(input, s) do
        true -> consume(s, input, index)
        _ -> {:fail, index}
      end
    end
  end

  def assert(f) do
    fn (input, index) ->
      case f.(input, index) do
        {:fail, index} -> {:fail, index}
        _ -> {[], input, index}
      end
    end
  end

  def not(f) do
    fn (input, index) ->
      case f.(input, index) do
        {:fail, index}-> {[], input, index}
        _ -> {:fail, index}
      end
    end
  end

  def optionnal(f) do
    fn (input, index) ->
      case f.(input, index) do
        {:fail, index} -> {[], input, index}
        res -> res
      end
    end
  end

  def choose(fns) do
    fn (input, index) ->
      attempt(fns, input, index, nil)
    end
  end

  defp attempt([], _input, _index, failure) do
    failure
  end
  defp attempt([f|fns], input, index, first_failure) do
    case f.(input, index) do
      {:fail, _} = failure ->
        case first_failure do
          nil -> attempt(fns, input, index, failure)
          _   -> attempt(fns, input, index, first_failure)
        end
      res -> res
    end
  end

  def sequence(fns) do
    fn (input, index) ->
      all(fns, input, [], index)
    end
  end

  defp all([], input, acc, index) do
    {Enum.reverse(acc), input, index}
  end
  defp all([f|fns], input, acc, index) do
    case f.(input, index) do
      {:fail, index} -> {:fail, index}
      {match, rest, new_index} -> all(fns, rest, [match|acc], new_index)
    end
  end

  def anything do
    fn (input, index) ->
      case input do
        "" -> {:fail, index}
        _ -> consume(String.first(input), input, index)
      end
    end
  end

  def charclass(class) do
    fn (input, index) ->
      case input do
        "" -> {:fail, index}
        _ ->
          s = String.first(input)
          {:ok, regex} = Regex.compile(class)
          case Regex.match? regex, s do
            true -> consume(s, input, index)
            _ -> {:fail, index}
          end
      end
    end
  end

  def one_or_more(f) do
    fn (input, index) ->
      case f.(input, index) do
        {:fail, index} -> {:fail, index}
        {matched, rest, new_index} -> do_one_or_more(f, matched, rest, new_index)
      end
    end
  end

  defp do_one_or_more(f, matched, remaining, index) do
    case f.(remaining, index) do
      {:fail, index} -> {matched, remaining, index}
      {next, rest, index} -> do_one_or_more(f, matched <> next, rest, index)
    end
  end

  def zero_or_more(f) do
    fn (input, index) ->
      case f.(input, index) do
        {:fail, _} -> {[], input, index}
        {matched, rest, index} -> do_one_or_more(f, matched, rest, index)
      end
    end
  end

  def tag(tag_name, f) do
    fn (input, index) ->
      case f.(input, index) do
        {match, rest, index} -> {{tag_name, match}, rest, index}
        _ ->
          {:fail, index}
      end
    end
  end

  def consume(s, input, index) do
    {s, remaining(input, String.length(s)), index + String.length(s)}
  end

  defp remaining(input, size) do
    remaining_length = String.length(input) - size
    String.slice(input, size, remaining_length)
  end
end
