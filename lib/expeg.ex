defmodule Expeg do
  def string(s) do
    fn (input) ->
      case String.starts_with?(input, s) do
        true ->
          consume(s, input)
        _ ->
          {:error, ""}
      end
    end
  end

  def assert(f) do
    fn (input) ->
      case f.(input) do
        {:error, _} ->
          {:error, ""}
        {_, _} ->
          {[], input}
      end
    end
  end

  def not(f) do
    fn (input) ->
      case f.(input) do
        {:error, _} ->
          {[], input}
        {_, _} ->
          {:error, ""}
      end
    end
  end

  def optionnal(f) do
    fn (input) ->
      case f.(input) do
        {:error, _} ->
          {[], input}
        {_, _} ->
          consume(String.at(input, 0), input)
      end
    end
  end

  def choose(f1, f2) do
    fn (input) ->
      case f1.(input) do
        {:error, _} ->
          case f2.(input) do
            {:error, _} ->
              {:error, ""}
            {match, rest} ->
              {match, rest}
          end
        {match, rest} ->
          {match, rest}
      end
    end
  end

  def sequence(f1, f2) do
    fn (input) ->
      case f1.(input) do
        {:error, _} ->
          {:error, ""}
        {matched1, rest1} ->
          case f2.(rest1) do
            {:error, _} ->
              {:error, ""}
            {matched2, rest2} ->
              {matched1 <> matched2, rest2}
          end
      end
    end
  end

  def anything do
    fn (input) ->
      case input do
        "" ->
          {:error, ""}
        _ ->
          consume(String.at(input, 0), input)
      end
    end
  end

  def charclass(class) do
    fn (input) ->
      s = String.at(input, 0)
      {:ok, regex} = Regex.compile(class)
      case Regex.match? regex, s do
        true ->
          consume(s, input)
        _ ->
          {:error, ""}
      end
    end
  end

  def one_or_more(f) do
    fn (input) ->
      case f.(input) do
        {:error, _} ->
          {:error, ""}
        {matched, rest} ->
          do_one_or_more(f, matched, rest)
      end
    end
  end

  defp do_one_or_more(f, matched, remaining) do
    case f.(remaining) do
      {:error, _} ->
        {matched, remaining}
      {next, rest} ->
        do_one_or_more(f, matched <> next, rest)
    end
  end

  def zero_or_more(f) do
    fn (input) ->
      case f.(input) do
        {:error, _} ->
          {[], input}
        {matched, rest} ->
          do_one_or_more(f, matched, rest)
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
