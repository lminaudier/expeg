defmodule UntransformedArithmetic do
  use Expeg

  @moduledoc """
  Implementation of Brian Ford's arithmetic grammar in it's thesis on Packrat Parsing

      additive  <- multitive "+" additive / multitive
      multitive <- primary "*" multitive / primary
      primary   <- "(" additive ")" / numeral
      numeral   <- [0-9]+
  """
  root(:additive)

  rule(:numeral) do
    one_or_more(charclass("[0-9]"))
  end

  rule(:additive) do
    choose([sequence([tag(:left, &multitive/2),
                      string("+"),
                      tag(:right, &additive/2)]),
            &multitive/2])
  end

  rule(:multitive) do
    choose([sequence([&primary/2,
                      string("*"),
                      &multitive/2]),
            &primary/2])
  end

  rule(:primary) do
    choose([sequence([string("("),
                      &additive/2,
                      string(")")]),
            &numeral/2])
  end
end

defmodule Arithmetic do
  use Expeg

  @moduledoc """
  Implementation of Brian Ford's arithmetic grammar in it's thesis on Packrat Parsing

      additive  <- multitive "+" additive / multitive
      multitive <- primary "*" multitive / primary
      primary   <- "(" additive ")" / numeral
      numeral   <- [0-9]+
  """
  root(:additive)

  rule(:numeral, :to_integer) do
    one_or_more(charclass("[0-9]"))
  end
  transform(:to_integer) do
    fn(node) ->
      binary_to_integer(node)
    end
  end

  rule(:additive, :add) do
    choose([sequence([tag(:left, &multitive/2),
                      string("+"),
                      tag(:right, &additive/2)]),
            &multitive/2])
  end
  transform(:add) do
    fn(node) ->
      case node do
        [{:left, a}, "+", {:right, b}] when is_integer(a) and is_integer(b) ->
          a + b
        _ ->
          node
      end
    end
  end

  rule(:multitive, :mult) do
    choose([sequence([&primary/2,
                      string("*"),
                      &multitive/2]),
            &primary/2])
  end
  transform(:mult) do
    fn(node) ->
      case node do
        [a, "*", b] when is_integer(a) and is_integer(b) ->
          a + b
        _ ->
          node
      end
    end
  end

  rule(:primary) do
    choose([sequence([string("("),
                      &additive/2,
                      string(")")]),
            &numeral/2])
  end
end

defmodule Integration.ArithmeticTest do
  use ExUnit.Case

  test "parses simple arithmetic grammar" do
    assert [{:left, "3"}, "+", {:right, "2"}] == UntransformedArithmetic.parse("3+2")
  end

  test "can transform ast while parsing" do
    assert 3 == Arithmetic.parse("3")
    assert 5 == Arithmetic.parse("3+2")
    assert 229 == Arithmetic.parse("13+210+2*3+1")
    assert {:fail, 0} == Arithmetic.parse("+2")
    assert {:fail, {3, "+", 1}} == Arithmetic.parse("3+")
  end
end
