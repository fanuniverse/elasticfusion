defmodule Elasticfusion.DocumentTest do
  use ExUnit.Case

  import Elasticfusion.IndexAPI
  alias Elasticfusion.Document

  defmodule Record do
    defstruct [:id, :tags, :stars, :date]
  end

  defmodule DocumentTestIndex do
    def index_name(), do: "document_test_index"

    def document_type(), do: "document_test_type"

    def settings(), do: %{number_of_shards: 1}

    def mapping(), do: %{
      "tags" => %{type: :keyword},
      "stars" => %{type: :integer},
      "date" => %{type: :date}
    }

    def keyword_field(), do: "tags"

    def serialize(%Record{tags: tags, stars: stars, date: date}) do
      %{"tags" => tags, "stars" => stars, "date" => date}
    end
  end

  setup do
    delete_index(DocumentTestIndex)
    :ok = create_index(DocumentTestIndex)
  end

  test "index/2 and remove/2" do
    test_record = %Record{
      id: 7, tags: "tag1, tag2", stars: 50, date: ~N[2017-02-03 16:20:00]}

    assert :ok = Document.index(test_record, DocumentTestIndex)
    Elastix.Index.refresh("localhost:9200", DocumentTestIndex.index_name())

    assert {:ok,
      %HTTPoison.Response{body: %{
          "hits" => %{"hits" => [%{
            "_id" => "7",
            "_source" => %{
              "date" => "2017-02-03T16:20:00",
              "stars" => 50,
              "tags" => "tag1, tag2"
          }}]}
        }}} =
      Elastix.Search.search("localhost:9200",
      DocumentTestIndex.index_name(),
      [DocumentTestIndex.document_type()],
      %{query: %{match_all: %{}}})

    assert :ok = Document.remove(test_record.id, DocumentTestIndex)
    Elastix.Index.refresh("localhost:9200", DocumentTestIndex.index_name())

    assert {:ok,
      %HTTPoison.Response{body: %{
          "hits" => %{"hits" => []}
        }}} =
      Elastix.Search.search("localhost:9200",
      DocumentTestIndex.index_name(),
      [DocumentTestIndex.document_type()],
      %{query: %{match_all: %{}}})
  end
end
