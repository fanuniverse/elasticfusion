defmodule Elasticfusion.Index do
  defmacro __using__(_opts) do
    quote do
      import Elasticfusion.Index

      @transforms []

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

  Default settings for Elasticsearch indexes are:
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

  An example:

  ```
  %{
    tags: %{type: :keyword},
    date: %{type: :date}
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
  Defines the mapping field used for keyword queries.

  An example:

  Given `:tag_names` as the keyword field,
  "tag one, tag two" is parsed as:
  ```
  %{bool: %{must: [
    %{term: %{tag_names: "tag one"}},
    %{term: %{tag_names: "tag two"}}
  ]}}
  ```
  """
  defmacro keyword_field(name) do
    quote do: @keyword_field unquote(name)
  end

  @doc """
  Defines fields that can occur in string queries
  (e.g. "field: value"), specified as a keyword list of
  `{:mapping_field, "text field"}`.

  Depending on the type specified in `mapping`,
  field values can be parsed as dates, numbers, or literals.
  """
  defmacro queryable_fields(fields) do
    quote do: @queryable_fields unquote(fields)
  end

  @doc """
  Defines a custom field query transform that produces
  an Elasticsearch query for a given field,
  qualifier (if present), value, and /external context/.

  The first argument specifies the field as encountered
  in a textual query (field is the part before the ':',
  e.g. "created by" for "created by: some user").

  The second argument is a function that takes 3 arguments:
  * a qualifier ("less than", "more than", "earlier than",
    "later than", or `nil`),
  * a value (value is the part after the ':' and an optional
    qualifier, e.g. "5" for "stars: less than 5"),
  * and /external context/ (see below),

  returning an Elasticsearch query.

  /external context/ is set by the caller of
  `Elasticfusion.Search.Builder.parse_search_string/3`.

  Consider the following examples:

  ```
  # "uploaded by: Cool Username"
  # =>
  # %{term: %{created_by: "cool username"}}

  def_transform "uploaded by", fn(_, username, _) ->
    indexed_username = String.downcase(username)
    %{term: %{created_by: indexed_username}}
  end

  # "found in: my favorites"
  # (external context: %User{name: "cool username"})
  # =>
  # %{term: %{favorited_by: "cool username"}}

  def_transform "found in", fn(_, "my favorites", %User{name: name}) ->
    %{term: %{favorited_by: name}}
  end

  # "starred by: less than 5 people"
  # =>
  # %{range: %{stars: %{lt: "5"}}}

  def_transform "starred by", fn
    ("less than", value, _) ->
      [_, count] = Regex.run(~r/(\\d+) people/, value)
      %{range: %{stars: %{lt: count}}}
    ("more than", value, _) ->
      [_, count] = Regex.run(~r/(\\d+) people/, value)
      %{range: %{stars: %{gt: count}}}
  end
  ```
  """
  defmacro def_transform(field, transform_fun_ast) do
    ast = Macro.escape(transform_fun_ast)
    quote do: @transforms [{unquote(field), unquote(ast)} | @transforms]
  end
end
