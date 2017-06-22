defmodule Elasticfusion.Document do
  import Elasticfusion.Utils, only: [status: 1]

  @doc """
  Adds (or replaces) a document at the `struct.id`.

  The `index` argument accepts a module that implements the
  `Elasticfusion.Index` behavior and returns a serialized
  (indexed) version of the `struct` via the
  `serialize/1` function.
  """
  def index(struct, index) do
    status(Elastix.Document.index(
      Application.get_env(:elasticfusion, :endpoint),
      index.index_name(),
      index.document_type(),
      struct.id,
      index.serialize(struct)))
  end

  @doc """
  Removes a document at the `id`.
  """
  def remove(id, index) do
    status(Elastix.Document.delete(
      Application.get_env(:elasticfusion, :endpoint),
      index.index_name(),
      index.document_type(),
      id))
  end
end
