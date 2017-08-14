defmodule Elasticfusion.Search.Lexer do
  @moduledoc """
  This module exposes functions for lexical scanning operations on a string.
  State tracking is explicit: functions receieve a state
  and return a tuple of {match, new_state}. Initial state is set up
  through `initialize/1`.

  All functions match the beginning of input (e.g. a matcher for "AND" matches
  "AND something", but not "something AND something") and consume all
  insignificant whitespace past the match.
  """

  @tokens [and: ~w{AND ,}, or: ~w{OR |}, not: ~w{NOT -}]
  @field_qualifiers ["less than", "more than", "earlier than", "later than"]
  @safe_string_until ~w{AND OR , | " ( )}
  @string_with_balanced_parentheses_until ~w{AND OR , |}

  import String, only: [trim: 1, trim_leading: 1]

  def initialize(input, queryable_fields) do
    %{
      input: trim_leading(input),
      queryable_fields: queryable_fields
    }
  end

  for {key, token} <- @tokens do
    def unquote(:"match_#{key}")(state),
      do: match_pattern(state, unquote(token))
  end

  def match_field(%{queryable_fields: []} = state),
    do: {nil, state}
  def match_field(%{queryable_fields: fields} = state) do
    case match_pattern(state, fields) do
      {field, %{input: rest} = new_state} when is_binary(field) ->
        case rest do
          ":" <> rest ->
            {field, %{new_state | input: trim_leading(rest)}}
          _ ->
            {nil, state}
        end
      _ ->
        {nil, state}
    end
  end

  def match_field_qualifier(state),
    do: match_pattern(state, @field_qualifiers)

  @doc """
  May contain words, numbers, spaces, dashes, and underscores.
  """
  def safe_sting(state),
    do: match_until(state, @safe_string_until)

  def string_with_balanced_parantheses(%{} = state) do
    case match_until(state, @string_with_balanced_parentheses_until) do
      {nil, _state} = no_match ->
        no_match
      {match, %{input: rest}} ->
        opening_parens =
          length(String.split(match, "(")) - 1
        balanced =
          match
          |> String.split(")")
          |> Enum.slice(0..opening_parens)
          |> Enum.join(")")

        balanced_len = byte_size(balanced)
        <<balanced::binary-size(balanced_len), cutoff::binary>> = match

        {trim(balanced), %{state | input: trim_leading(cutoff) <> rest}}
    end
  end

  def quoted_string(%{input: input} = state) do
    case Regex.run(~r/"((?:\\.|[^"])*)"/, input, return: :index, capture: :all_but_first) do
      [{1, len}] ->
        <<quotemark::binary-size(1),
          quoted::binary-size(len),
          quotemark::binary-size(1),
          rest::binary>> = input
        quoted =
          quoted
          |> String.replace(~r/\\"/, "\"")
          |> String.replace(~r/\\\\/, "\\")
        {quoted, %{state | input: trim_leading(rest)}}
      _ ->
        {nil, state}
    end
  end

  def left_parentheses(%{input: input} = state) do
    case Regex.run(~r/^(\(\s*)+/, input, capture: :first) do
      [match] ->
        match_len = byte_size(match)
        <<_::binary-size(match_len), rest::binary>> = input

        count =
          match
          |> String.graphemes
          |> Enum.count(&Kernel.==(&1, "("))

        {count, %{state | input: rest}}
      _ ->
        {nil, state}
    end
  end

  def right_parentheses(%{input: input} = state, count) do
    case Regex.run(~r/^(\)\s*){#{count}}/, input, capture: :first) do
      [match] ->
        match_len = byte_size(match)
        <<_::binary-size(match_len), rest::binary>> = input
        {count, %{state | input: rest}}
      _ ->
        {nil, state}
    end
  end

  # Internal

  def match_pattern(%{input: input} = state, pattern) do
    case :binary.match(input, pattern) do
      {0, len} ->
        <<match::binary-size(len), rest::binary>> = input
        {match, %{state | input: trim_leading(rest)}}
      _ ->
        {nil, state}
    end
  end

  defp match_until(%{input: input} = state, pattern) do
    case :binary.match(input, pattern) do
      {len, _} ->
        <<matched::binary-size(len), rest::binary>> = input
        {trim(matched), %{state | input: trim_leading(rest)}}
      :nomatch ->
        {input, %{state | input: ""}}
    end
  end
end
