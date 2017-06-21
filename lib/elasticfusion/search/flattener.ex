defmodule Elasticfusion.Search.Flattener do
  @doc """
  Transforms a binary tree-like representation of a query
  into a multi-way tree-like.

  This mainly applies to nested logical expressions with two operands,
  which are flattened into a single one with multiple operands.

  ## Examples

      iex> Elasticfusion.Search.Flattener.flatten(
      ...> {:and,
      ...>   "A",
      ...>   {:and,
      ...>     "B",
      ...>     {:and,
      ...>       "C",
      ...>       {:or, "D", "E"}}}})
      {:and, ["A", "B", "C", {:or, ["D", "E"]}]}
  """
  def flatten(inner, outer \\ {})
  def flatten({op, left, right} = inner, {op, _, _} = _outer) do
    List.wrap(flatten(left, inner)) ++ List.wrap(flatten(right, inner))
  end
  def flatten({op, left, right} = inner, _outer) do
    {op, List.wrap(flatten(left, inner)) ++ List.wrap(flatten(right, inner))}
  end
  def flatten({:not, expression}, _outer), do: {:not, flatten(expression)}
  def flatten(expression, _outer), do: expression
end
