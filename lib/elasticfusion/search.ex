defmodule Elasticfusion.Search do
  @doc """
  Runs an Elasticsearch query constructed by
  `Elasticfusion.Search.Builder` and returns a tuple of
  `{:ok, ids of documents that matched}`
  or `{:error, %HTTPoison.Response}`.
  """
  def find_ids(query, index) do
    response = Elastix.Search.search(
      Application.get_env(:elasticfusion, :endpoint),
      index.index_name(),
      [index.document_type()],
      query)

    case response do
      {:ok, %HTTPoison.Response{body: %{"hits" => %{"hits" => hits}}}} ->
        ids =
          Enum.map(hits, fn(%{"_id" => id}) -> id end)

        {:ok, ids}
      error ->
        error
    end
  end
end
