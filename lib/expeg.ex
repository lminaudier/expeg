defmodule Expeg do
  defmacro __using__(_) do
    quote do
      import unquote(__MODULE__)
    end
  end

  defmacro rule(name, do: derivation) do
    quote do
      def unquote(name)(input) do
        unquote(derivation).(input)
      end
    end
  end

  defmacro root(name) do
    quote do
      def parse(input) do
        case unquote(name)(input) do
          {ast, ""} -> ast
          _ -> :fail
        end
      end
    end
  end

  def string(s) do
    fn (input) ->
      case String.starts_with?(input, s) do
        true -> consume(s, input)
        _ -> :fail
      end
    end
  end

  def assert(f) do
    fn (input) ->
      case f.(input) do
        :fail -> :fail
        _ -> {[], input}
      end
    end
  end

  def not(f) do
    fn (input) ->
      case f.(input) do
        :fail -> {[], input}
        _ -> :fail
      end
    end
  end

  def optionnal(f) do
    fn (input) ->
      case f.(input) do
        :fail -> {[], input}
        res -> res
      end
    end
  end

  def choose(fns) do
    fn (input) ->
      attempt(fns, input, nil)
    end
  end

  defp attempt([], input, failure) do
    failure
  end
  defp attempt([f|fns], input, first_failure) do
    case f.(input) do
      :fail = failure ->
        case first_failure do
          nil -> attempt(fns, input, failure)
          _ -> attempt(fns, input, first_failure)
        end
      res -> res
    end
  end

  def sequence(fns) do
    fn (input) ->
      all(fns, input, [])
    end
  end

  defp all([], input, acc) do
    {Enum.reverse(acc), input}
  end
  defp all([f|fns], input, acc) do
    case f.(input) do
      :fail -> :fail
      {match, rest} -> all(fns, rest, [match|acc])
    end
  end

  def anything do
    fn (input) ->
      case input do
        "" -> :fail
        _ -> consume(String.first(input), input)
      end
    end
  end

  def charclass(class) do
    fn (input) ->
      case input do
        "" -> :fail
        _ ->
          s = String.first(input)
          {:ok, regex} = Regex.compile(class)
          case Regex.match? regex, s do
            true -> consume(s, input)
            _ -> :fail
          end
      end
    end
  end

  def one_or_more(f) do
    fn (input) ->
      case f.(input) do
        :fail -> :fail
        {matched, rest} -> do_one_or_more(f, matched, rest)
      end
    end
  end

  defp do_one_or_more(f, matched, remaining) do
    case f.(remaining) do
      :fail -> {matched, remaining}
      {next, rest} -> do_one_or_more(f, matched <> next, rest)
    end
  end

  def zero_or_more(f) do
    fn (input) ->
      case f.(input) do
        :fail -> {[], input}
        {matched, rest} -> do_one_or_more(f, matched, rest)
      end
    end
  end

  def consume(s, input) do
    {s, remaining(input, String.length(s))}
  end

  defp remaining(input, size) do
    remaining_length = String.length(input) - size
    String.slice(input, size, remaining_length)
  end
end
