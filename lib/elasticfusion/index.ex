defmodule Elasticfusion.Index do
  defmacro __using__(_opts) do
    quote do
      import Elasticfusion.Index

      @before_compile Elasticfusion.Index
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

  # Internal

  import Module, only: [get_attribute: 2]

  defmacro __before_compile__(%{module: module}) do
    [
      for required_attr <- ~w(index_name document_type)a do
        case get_attribute(module, required_attr) do
          value when not is_nil(value) ->
            quote do: (def unquote(required_attr)(), do: unquote(value))
          _ ->
            raise """
            #{required_attr} is not specified; set it using `#{required_attr}/1`
            """
        end
      end,

      case get_attribute(module, :index_settings) do
        settings when is_map(settings) ->
          settings = Macro.escape(settings)
          quote do: (def index_settings, do: unquote(settings))
        _ ->
          quote do: (def index_settings, do: %{})
      end,

      case get_attribute(module, :mapping) do
        mapping when is_map(mapping) ->
          Enum.each(mapping, fn
            {field, _} when is_binary(field) ->
              :ok
            {_, _} ->
              raise """
              You must use binaries for mapping fields
              """
          end)

          mapping = Macro.escape(mapping)
          quote do: (def mapping, do: unquote(mapping))
        _ ->
          raise """
          Index mapping is not specified; set it using `mapping/1`
          """
      end,

      case get_attribute(module, :serialize_fun_ast) do
        fun_ast when not is_nil(fun_ast) ->
          quote do: (def serialize(s), do: unquote(fun_ast).(s))
        _ ->
          raise """
          Serialization function is undefined; set it using `serialize/1`
          """
      end,

      case get_attribute(module, :keyword_field) do
        field when is_binary(field) ->
          if field not in (module |> get_attribute(:mapping) |> Map.keys()) do
            raise """
            Keyword field is not present in the mapping defined in `mapping/1`
            """
          end

          field = Macro.escape(field)
          quote do: (def keyword_field, do: unquote(field))
        _ ->
          quote do: (def keyword_field, do: "")
      end,

      case get_attribute(module, :queryable_fields) do
        queryable_fields when is_list(queryable_fields) ->
          unmapped = queryable_fields -- Map.keys(get_attribute(module, :mapping))

          case unmapped do
            [] ->
              quote do: (def queryable_fields, do: unquote(queryable_fields))
            [field] ->
              raise """
              Queryable field #{field} \
              is not present in the mapping defined in `mapping/1`
              """
            fields ->
              raise """
              Queryable fields #{Enum.join(fields, ", ")} \
              are not present in the mapping defined in `mapping/1`
              """
          end
        _ ->
          quote do: (def queryable_fields, do: [])
      end
    ]
  end
end
