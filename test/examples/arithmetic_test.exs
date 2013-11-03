defmodule Arithmetic do
  use Expeg

  @moduledoc """
  Implementation of Brian Ford's arithmetic grammar in it's thesis on Packrat Parsing

      additive  <- multitive "+" additive / multitive
      multitive <- primary "*" multitive / primary
      primary   <- "(" additive ")" / numeral
      numeral   <- [0-9]+
  """
  rule(:numeral) do
    one_or_more(charclass("[0-9]"))
  end

  rule(:additive) do
    choose([sequence([&multitive/1,
                      string("+"),
                      &additive/1]),
            &multitive/1])
  end

  rule(:multitive) do
    choose([sequence([&primary/1,
                      string("*"),
                      &multitive/1]),
            &primary/1])
  end

  rule(:primary) do
    choose([sequence([string("("),
                      &additive/1,
                      string(")")]),
            &numeral/1])
  end

  def parse(input) do
    case additive(input) do
      {ast, ""} ->
        ast
      _ ->
        :error
    end
  end
end

defmodule Integration.ArithmeticTest do
  use ExUnit.Case

  test "parses simple arithmetic grammar" do
    assert ["3", "+", "2"] == Arithmetic.parse("3+2")
    assert ["13", "+", ["210", "+", [["2", "*", "3"], "+", "1"]]] == Arithmetic.parse("13+210+2*3+1")
    assert :error == Arithmetic.parse("+2")
    assert :error == Arithmetic.parse("3+")
  end
end
