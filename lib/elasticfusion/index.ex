defmodule Elasticfusion.Index do
  @callback index_name() :: binary

  @callback definition() :: map

  @callback keyword_field() :: atom

  @callback serialize(struct) :: map
end
