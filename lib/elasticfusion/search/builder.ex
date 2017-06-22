defmodule Elasticfusion.Search.Builder do
  @moduledoc """
  A module for constructing Elasticsearch queries
  that can be executed by `Elasticfusion.Search`.
  """

  alias Elasticfusion.Search.Parser
  alias Elasticfusion.Search.ElasticQuery

  @doc """
  Returns an Elasticsearch query parsed from a given string.
  """
  def parse_search_string(str, index) do
    query =
      str
      |> Parser.query(index.queryable_fields())
      |> ElasticQuery.build(index)

    # NOTE IMPORTANT: The subset of queries that is currently supported
    # is executed in the filter context, which is faster
    # (does not compute _score and can be cached)
    # but cannot be used for relevance sorting and wildcard queries.
    %{query: %{bool: %{filter: [query]}}}
  end

  @doc """
  Sets `:size` and `:from` properties in a given Elasticsearch query
  based on the `page` and `per_page` arguments.

  ## Examples

  iex> Elasticfusion.Search.Builder.paginate(%{query: %{match_all: %{}}}, 0, 10)
  %{query: %{match_all: %{}}, from: 0, size: 10}

  iex> Elasticfusion.Search.Builder.paginate(%{query: %{match_all: %{}}}, 1, 10)
  %{query: %{match_all: %{}}, from: 0, size: 10}

  iex> Elasticfusion.Search.Builder.paginate(%{query: %{match_all: %{}}}, 2, 10)
  %{query: %{match_all: %{}}, from: 10, size: 10}

  iex> Elasticfusion.Search.Builder.paginate(%{query: %{match_all: %{}}}, 3, 20)
  %{query: %{match_all: %{}}, from: 40, size: 20}
  """
  def paginate(query, page, per_page) do
    page = max(page, 1)
    per_page = max(per_page, 1)

    offset = (page - 1) * per_page

    query
    |> Map.put(:size, per_page)
    |> Map.put(:from, offset)
  end

  @doc """
  Appends a clause to the _query context_ of a given Elasticsearch query.
  See https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
  """
  def add_query_clause(query, clause) do
    query = if query[:query],
      do: query, else: put_in(query[:query], %{})
    query = if query[:query][:bool],
      do: query, else: put_in(query[:query][:bool], %{})

    if query[:query][:bool][:must],
      do: update_in(query[:query][:bool][:must], &(&1 ++ [clause])),
      else: put_in(query[:query][:bool][:must], [clause])
  end

  @doc """
  Appends a clause to the _filter context_ of a given Elasticsearch query.
  See https://www.elastic.co/guide/en/elasticsearch/reference/current/query-filter-context.html
  """
  def add_filter_clause(query, clause) do
    query = if query[:query],
      do: query, else: put_in(query[:query], %{})
    query = if query[:query][:bool],
      do: query, else: put_in(query[:query][:bool], %{})

    if query[:query][:bool][:filter],
      do: update_in(query[:query][:bool][:filter], &(&1 ++ [clause])),
      else: put_in(query[:query][:bool][:filter], [clause])
  end

  @doc """
  Appends a sort clause to a given Elasticsearch query.
  """
  def add_sort(query, field, direction) when direction in [:asc, :desc] do
    sort = %{field => direction}

    Map.update(query, :sort, [sort],
      fn(sorts) -> sorts ++ [sort] end)
  end
end
