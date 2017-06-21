defmodule Elasticfusion.Index do
  @moduledoc """
  A behavior that defines a queryable index.

  `c:index_name/0` specifies the index name and
  `c:document_type/0` specifies the document type
  (see https://www.elastic.co/blog/index-vs-type).

  `c:settings/0` specifies a map of index settings
  (https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-create-index.html#create-index-settings),
  e.g.
  ```
  %{number_of_shards: 1}
  ```

  `c:mapping/0` specifies the explicit mapping for the document type,
  with all keys being atoms _except_ for field names, e.g.
  ```
  %{
    "tags" => %{type: :keyword},
    "date" => %{type: :date}
  }
  ```
  This is required for string query parsing.

  `c:keyword_field/0` specifies the name of the field
  used for keyword queries ("keyword one, keyword two").

  `c:serialize/1` serializes a struct for indexing. It
  should return a map containing all fields in the mapping
  and their corresponding values. See `Elasticfusion.Document`
  for more information on indexing operations.
  """

  @callback index_name() :: binary

  @callback document_type() :: binary

  @callback settings() :: map

  @callback mapping() :: map

  @callback keyword_field() :: binary

  @callback serialize(struct) :: map
end
