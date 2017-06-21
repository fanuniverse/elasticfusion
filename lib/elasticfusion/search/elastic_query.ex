defmodule Elasticfusion.Search.ElasticQuery do
  @es_operators %{
    and: :must,
    or: :should
  }

  import Enum, only: [map: 2]
  import Elasticfusion.Search.Flattener

  @doc """
  Transforms an expression tree produced by
  `Elasticfusion.Search.Parser` into an Elasticsearch query.

  The `keyword_field` argument specifies the field to be used
  for string terms.
  """
  def build(expression, keyword_field) do
    transform(flatten(expression), {keyword_field})
  end

  def transform({:not, {:and, children}}, state) do
    operands = map(children, &transform(&1, state))

    %{bool: %{must_not: operands}}
  end
  def transform({:not, expression}, state) do
    clause = [transform(expression, state)]

    %{bool: %{must_not: clause}}
  end
  def transform({op, children}, state) do
    operator = @es_operators[op]
    operands = map(children, &transform(&1, state))

    %{bool: %{operator => operands}}
  end
  def transform({:field_query, field, nil, value}, _state) do
    %{term: %{field => value}}
  end
  def transform({:field_query, field, qualifier, value}, _state) do
    %{range: %{field => %{qualifier =>  value}}}
  end
  def transform(keyword_term, {keyword_field}) do
    %{term: %{keyword_field => keyword_term}}
  end
end
