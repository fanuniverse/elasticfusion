defmodule Elasticfusion.Search do
  @doc """
  Runs an Elasticsearch query constructed by
  `Elasticfusion.Search.Builder` and returns a tuple of
  `{:ok, ids of documents that matched}`
  or `{:error, %HTTPoison.Response}`.
  """
  def find_ids(query, index) do
    query = Map.put(query, :_source, false)
    options = [filter_path: "hits.hits._id"]

    response = Elastix.Search.search(
      Application.get_env(:elasticfusion, :endpoint),
      index.index_name(),
      [index.document_type()],
      query, options)

    case response do
      {:ok, %HTTPoison.Response{body: %{"hits" => %{"hits" => hits}}}} ->
        {:ok, Enum.map(hits, fn(%{"_id" => id}) -> id end)}
      {:ok, %HTTPoison.Response{body: %{}, status_code: 200}} ->
        {:ok, []}
      error ->
        error
    end
  end
end
