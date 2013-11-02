defmodule Arithmetic do
  import Expeg

  @moduledoc """
  Implementation of Brian Ford's arithmetic grammar in it's thesis on Packrat Parsing

      additive  <- multitive "+" additive / multitive
      multitive <- primary "*" multitive / primary
      primary   <- "(" additive ")" / numeral
      numeral   <- [0-9]
  """
  def numeral(input) do
    charclass("[0-9]").(input)
  end

  def additive(input) do
    choose([sequence([&multitive/1,
                      string("+"),
                      &additive/1]),
            &multitive/1]).(input)
  end

  def multitive(input) do
    choose([sequence([&primary/1,
                      string("*"),
                      &multitive/1]),
            &primary/1]).(input)
  end

  def primary(input) do
    choose([sequence([string("("),
                      &additive/1,
                      string(")")]),
            &numeral/1]).(input)
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
    assert :error == Arithmetic.parse("+2")
    assert :error == Arithmetic.parse("3+")
  end
end
