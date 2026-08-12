defmodule SRTM.Error do
  @moduledoc """
  The SRTM error struct.
  """

  @type t :: %__MODULE__{
          reason: atom() | tuple(),
          message: String.t()
        }

  defexception [:reason, :message]
end
