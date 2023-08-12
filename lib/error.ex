defmodule SRTM.Error do
  @moduledoc """
  The SRTM error struct.
  """

  @type t :: %__MODULE__{
          reason: atom,
          message: String.t()
        }

  defexception [:reason, :message]
end
