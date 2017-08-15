defmodule Elasticfusion.DocumentTest do
  use ExUnit.Case

  import Elasticfusion.IndexAPI
  alias Elasticfusion.Document

  defmodule Record do
    defstruct [:id, :tags, :stars, :date]
  end

  defmodule DocumentTestIndex do
    use Elasticfusion.Index

    index_name "document_test_index"
    document_type "document_test_type"
    index_settings %{number_of_shards: 1}

    mapping %{
      tags: %{type: :keyword},
      stars: %{type: :integer},
      date: %{type: :date}
    }

    serialize &(%{tags: &1.tags, stars: &1.stars, date: &1.date})

    keyword_field :tags
  end

  setup do
    delete_index(DocumentTestIndex)
    :ok = create_index(DocumentTestIndex)
  end

  test "index/2 and remove/2" do
    test_record = %Record{
      id: 7, tags: ~w(tag1 tag2), stars: 50, date: ~N[2017-02-03 16:20:00]}

    assert :ok = Document.index(test_record, DocumentTestIndex)
    Elastix.Index.refresh("localhost:9200", DocumentTestIndex.index_name())

    assert {:ok,
      %HTTPoison.Response{body: %{
          "hits" => %{"hits" => [%{
            "_id" => "7",
            "_source" => %{
              "date" => "2017-02-03T16:20:00",
              "stars" => 50,
              "tags" => ~w(tag1 tag2)
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
