defmodule SRTM.Error do
  @moduledoc """
  The error struct.
  """

  @type t :: %__MODULE__{
          reason: atom,
          message: String.t()
        }

  @enforce_keys [:reason, :message]
  defstruct [:reason, :message]
end
