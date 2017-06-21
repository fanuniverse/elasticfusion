defmodule Elasticfusion.Search.LexerTest do
  use ExUnit.Case

  alias Elasticfusion.Search.Lexer
  alias Elasticfusion.Search.Lexer.State

  test "matches a token and consumes whitespace past it" do
    {match, state} = run(&Lexer.match(&1, :and),
      "AND something else")
    assert "AND" == match
    assert ^state = %State{input: "something else"}
  end

  test "matches safe strings" do
    {match, state} = run(&Lexer.safe_sting/1,
      "safe string with - and _ and 20 17")
    assert match == "safe string with - and _ and 20 17"
    assert ^state = %State{input: ""}

    {match, state} = run(&Lexer.safe_sting/1,
      "safe string with - and _ and 20 17, irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert ^state = %State{input: ", irrelevant part"}

    {match, state} = run(&Lexer.safe_sting/1,
      "safe string with - and _ and 20 17    | irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert ^state = %State{input: "| irrelevant part"}

    {match, state} = run(&Lexer.safe_sting/1,
      "safe string with - and _ and 20 17 OR irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert ^state = %State{input: "OR irrelevant part"}
  end

  test "matches strings with balanced parentheses" do
    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "(safe string) with - and _ (and) 20 17 and (balanced)")
    assert match == "(safe string) with - and _ (and) 20 17 and (balanced)"
    assert ^state = %State{input: ""}

    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "(safe string) with - and _    ")
    assert match == "(safe string) with - and _"
    assert ^state = %State{input: ""}

    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "(safe string) (balanced)) ")
    assert match == "(safe string) (balanced)"
    assert ^state = %State{input: ") "}

    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "safe string with - and _ and 20 17), irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert ^state = %State{input: "), irrelevant part"}

    {match, state} = run(&Lexer.string_with_balanced_parantheses/1,
      "safe string with - and _ and 20 17    OR irrelevant part")
    assert match == "safe string with - and _ and 20 17"
    assert ^state = %State{input: "OR irrelevant part"}
  end

  test "matches quoted strings" do
    {match, state} = run(&Lexer.quoted_string/1,
      ~S{"this is a \"quoted\" string ) , AND OR ((( "})
    assert match == ~s{this is a "quoted" string ) , AND OR ((( }
    assert ^state = %State{input: ""}

    {match, state} = run(&Lexer.quoted_string/1,
      ~S{"this is a \"quoted\" string ) , AND OR ((( "irrelevant part})
    assert match == ~S{this is a "quoted" string ) , AND OR ((( }
    assert ^state = %State{input: "irrelevant part"}

    {match, state} = run(&Lexer.quoted_string/1,
      ~S{"\"beginning\" and ending with a \"quote\""   , irrelevant part})
    assert match == ~S{"beginning" and ending with a "quote"}
    assert ^state = %State{input: ", irrelevant part"}

    {match, state} = run(&Lexer.quoted_string/1,
      ~S{"one string" BUT WAIT "there's more"})
    assert match == ~S{one string}
    assert ^state = %State{input: ~S{BUT WAIT "there's more"}}
  end

  test "matches parentheses" do
    {count, state} = run(&Lexer.left_parentheses/1,
      "( (   (    (     unrelated")
    assert count == 4
    assert ^state = %State{input: "unrelated"}

    {count, state} = run(&Lexer.left_parentheses/1,
      " no parentheses")
    assert count == nil
    assert ^state = %State{input: "no parentheses"}

    {count, state} = run(&Lexer.right_parentheses(&1, 3),
      ")    ) )) )) unrelated ))")
    assert count == 3
    assert ^state = %State{input: ") )) unrelated ))"}

    {count, state} = run(&Lexer.right_parentheses(&1, 6),
      ")    ) )) )) unrelated ))")
    assert count == 6
    assert ^state = %State{input: "unrelated ))"}

    {count, state} = run(&Lexer.right_parentheses(&1, 8),
      ")    ) )) )) unrelated ))")
    assert count == nil
    assert ^state = %State{input: ")    ) )) )) unrelated ))"}

    {count, state} = run(&Lexer.right_parentheses(&1, 1),
      " no parentheses")
    assert count == nil
    assert ^state = %State{input: "no parentheses"}
  end

  defp run(fun, input) when is_function(fun, 1) and is_binary(input) do
    input
    |> Lexer.initialize([])
    |> fun.()
  end
end
