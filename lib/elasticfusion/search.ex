defmodule Elasticfusion.Search do
  @doc """
  Runs an Elasticsearch query constructed by
  `Elasticfusion.Search.Builder` and returns a tuple of
  `{:ok,
    ids of documents that matched,
    total number of documents that matched (i.e. without the size clause)}`
  or `{:error, %HTTPoison.Response}`.
  """
  def find_ids(query, index) do
    query = Map.put(query, :_source, false)
    options = [filter_path: "hits.hits._id,hits.total"]

    response = Elastix.Search.search(
      Application.get_env(:elasticfusion, :endpoint),
      index.index_name(),
      [index.document_type()],
      query, options)

    case response do
      {:ok, %HTTPoison.Response{body: %{"hits" => %{"hits" => hits, "total" => total}}}} ->
        ids = Enum.map(hits, fn(%{"_id" => id}) -> id end)
        {:ok, ids, total}
      {:ok, %HTTPoison.Response{body: %{"hits" => %{"total" => 0}}}} ->
        {:ok, [], 0}
      error ->
        error
    end
  end
end
