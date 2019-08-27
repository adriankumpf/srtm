defmodule SRTM.Error do
  @moduledoc """
  The error struct.
  """

  @enforce_keys [:reason, :message]
  defstruct [:reason, :message]
  @type t :: %__MODULE__{reason: atom, message: String.t()}
end
