defmodule Elasticfusion.Peek do
  @moduledoc """
  This module includes functions for returning consecutive (previous and next)
  IDs for a given struct and a query that matches it.

  Under the hood, it uses `search_after` parameters — see
  https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-search-after.html.

  The queries provided to `next_id/3` and `previous_id/3` _must_ have
  at least one sorting clause, preferably with unique values to
  ensure deterministic order.
  """

  alias Elasticfusion.Search

  def next_id(struct, query, index) do
    response =
      struct
      |> serialize(index)
      |> query_after(query)
      |> Search.find_ids(index)

    case response do
      {:ok, ids} when is_list(ids) ->
        {:ok, List.first(ids)}
      error ->
        error
    end
  end

  def previous_id(struct, query, index) do
    reverse_query = reverse_sort(query)

    next_id(struct, reverse_query, index)
  end

  defp serialize(struct, index) do
    struct
    |> index.serialize()
    |> Map.put_new("_id", struct.id)
  end

  defp query_after(serialized, query) do
    query
    |> Map.put(:from, 0)
    |> Map.put(:size, 1)
    |> Map.put(:search_after, Enum.map(query[:sort],
        fn(sort) ->
          [{field, _direction}] = Map.to_list(sort)
          case serialized[field] do
            %NaiveDateTime{} = date ->
              date
              |> DateTime.from_naive!("Etc/UTC")
              |> DateTime.to_unix(:millisecond)
            other ->
              other
          end
        end))
  end

  defp reverse_sort(query) do
    update_in(query[:sort], &Enum.map(&1, fn(sort) ->
      case Map.to_list(sort) do
        [{field, :asc}] -> %{field => :desc}
        [{field, :desc}] -> %{field => :asc}
      end
    end))
  end
end
