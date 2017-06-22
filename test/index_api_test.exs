defmodule Elasticfusion.IndexAPITest do
  use ExUnit.Case

  import Elasticfusion.IndexAPI

  defmodule IndexAPITestIndex do
    def index_name(),       do: "index_api_test_index"
    def document_type(),    do: "index_api_test_type"
    def settings(),         do: %{number_of_shards: 2}
    def mapping(),          do: %{"inserted_at" => %{type: :date}}
    def keyword_field(),    do: "tags"
    def queryable_fields(), do: []
    def serialize(_),       do: nil
  end

  setup do
    delete_index(IndexAPITestIndex)
    :ok
  end

  test "create_index/1 and delete_index/1" do
    assert :ok = create_index(IndexAPITestIndex)

    index = IndexAPITestIndex.index_name()
    doc = IndexAPITestIndex.document_type()

    assert {:ok,
      %HTTPoison.Response{body: %{
        ^index => %{
          "mappings" => %{^doc =>
            %{"properties" => %{"inserted_at" => %{"type" => "date"}}}},
          "settings" => %{"index" => %{"number_of_shards" => "2"}}
        }}}} =
      Elastix.Index.get("localhost:9200", index)

    assert :ok = delete_index(IndexAPITestIndex)

    assert {:ok,
      %HTTPoison.Response{body: %{
        "error" => %{
          "index" => ^index,
          "reason" => "no such index"
        }}}} =
      Elastix.Index.get("localhost:9200", index)
  end
end
