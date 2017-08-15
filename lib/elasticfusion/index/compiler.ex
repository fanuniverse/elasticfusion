defmodule Elasticfusion.Index.Compiler do
  import Module, only: [get_attribute: 2]

  defmacro compile_index(%{module: module}) do
    [
      for required_attr <- ~w(index_name document_type)a do
        case get_attribute(module, required_attr) do
          value when not is_nil(value) ->
            quote do: (def unquote(required_attr)(), do: unquote(value))
          _ ->
            raise "#{required_attr} is not specified; " <>
              "set it using `#{required_attr}/1`"
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
              raise "You must use binaries for mapping fields"
          end)

          mapping = Macro.escape(mapping)
          quote do: (def mapping, do: unquote(mapping))
        _ ->
          raise "Index mapping is not specified; " <>
            "set it using `mapping/1`"
      end,

      case get_attribute(module, :serialize_fun_ast) do
        fun_ast when not is_nil(fun_ast) ->
          quote do: (def serialize(s), do: unquote(fun_ast).(s))
        _ ->
          raise "Serialization function is undefined; " <>
            "set it using `serialize/1`"
      end,

      case get_attribute(module, :keyword_field) do
        field when is_binary(field) ->
          if field not in (module |> get_attribute(:mapping) |> Map.keys()) do
            raise "Keyword field is not present " <>
              "in the mapping defined in `mapping/1`"
          end

          field = Macro.escape(field)
          quote do: (def keyword_field, do: unquote(field))
        _ ->
          quote do: (def keyword_field, do: "")
      end,

      case get_attribute(module, :queryable_fields) do
        fields when is_list(fields) ->
          for field <- fields do
            field_transform(field, field, get_attribute(module, :mapping))
          end
        _ ->
          []
      end,

      custom_field_transforms(module),

      queryable_fields(module)
    ]
  end

  def field_transform(field, query, mapping) do
    value_transform =
      case mapping[field] do
        %{type: :date} ->
          quote do: Elasticfusion.Utils.parse_nl_date(value)
        %{type: _other_type} ->
          quote do: value
        %{} ->
          raise "Type declaration for queryable field `#{field}` " <>
            "is not present in the mapping defined in `mapping/1`"
        nil ->
          raise "Queryable field `#{field}` " <>
            "is not present in the mapping defined in `mapping/1`"
      end

    qualifiers =
      case mapping[field] do
        %{type: :date} ->
          [lt: "earlier than", gt: "later than"]
        _ ->
          [lt: "less than", gt: "more than"]
      end

    for {q, q_text} <- qualifiers do
      quote do:
        def transform(unquote(query), unquote(q_text), value, _),
          do: %{range: %{unquote(field) => %{unquote(q) => unquote(value_transform)}}}
    end ++ [
      quote do:
        def transform(unquote(query), _, value, _),
          do: %{term: %{unquote(field) => unquote(value_transform)}}
    ]
  end

  def custom_field_transforms(module) do
    transforms = get_attribute(module, :transforms) || []

    for {field, fun_ast} <- transforms do
      quote do:
        def transform(unquote(field), qualifier, value, context),
          do: unquote(fun_ast).(qualifier, value, context)
    end
  end

  def queryable_fields(module) do
    queryable_fields = get_attribute(module, :queryable_fields) || []
    field_transforms = (get_attribute(module, :transforms) || [])
      |> Enum.map(fn({field, _}) -> field end)

    fields = Macro.escape(queryable_fields ++ field_transforms)

    quote do
      def queryable_fields, do: unquote(fields)
    end
  end
end
