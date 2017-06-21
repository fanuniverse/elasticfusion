defmodule Elasticfusion.Index do
  @callback index_name() :: String.t

  @callback definition() :: map

  @callback serialize(struct) :: map
end
