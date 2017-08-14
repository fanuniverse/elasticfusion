defmodule Elasticfusion.Index do
  defmacro __using__(_opts) do
    quote do
      import Elasticfusion.Index

      @before_compile {Elasticfusion.Index.Compiler, :compile_index}
    end
  end

  @doc """
  Defines the searchable index name.

  This setting is required.
  """
  defmacro index_name(name) do
    quote do: @index_name unquote(name)
  end

  @doc """
  Defines the document type.
  See https://www.elastic.co/blog/index-vs-type for differences
  between index names and document types.

  This setting is required.
  """
  defmacro document_type(type) do
    quote do: @document_type unquote(type)
  end

  @doc """
  Defines index settings applied on index (re)creation.
  See https://www.elastic.co/guide/en/elasticsearch/reference/current/index-modules.html
  for available settings.

  Default settings for Elasticsearch indexes are
  ```
  %{
    number_of_shards: 5,
    number_of_replicas: 1
  }
  ```
  """
  defmacro index_settings(settings) do
    quote do: @index_settings unquote(settings)
  end

  @doc """
  Defines explicit mapping for the document type,
  set on index (re)creation.

  Specify field names as binaries and settings as atoms, e.g.:
  ```
  %{
    "tags" => %{type: :keyword},
    "date" => %{type: :date}
  }
  ```

  This setting is required.
  """
  defmacro mapping(mapping) do
    quote do: @mapping unquote(mapping)
  end

  @doc """
  Defines a serialization function that produces a map
  of indexed fields and their corresponding values
  given a record struct.

  See `Elasticfusion.Document` for more information
  on indexing operations.

  This setting is required.
  """
  defmacro serialize(fun_ast) do
    ast = Macro.escape(fun_ast)
    quote do: @serialize_fun_ast unquote(ast)
  end

  @doc """
  Defines field used for keyword queries
  (e.g. "keyword one, keyword two").
  """
  defmacro keyword_field(name) do
    quote do: @keyword_field unquote(name)
  end

  @doc """
  Defines fields that can occur in string queries
  (e.g. "field: value").

  Depending on the type specified in `mapping`,
  field values can be parsed as dates, numbers, or literals.
  """
  defmacro queryable_fields(fields) do
    quote do: @queryable_fields unquote(fields)
  end
end
