defmodule Srtm.Source do
  @moduledoc false

  @callback fetch(client :: Tesla.Client.t(), path :: Path.t(), name :: String.t()) ::
              {:ok, hgt_path :: Path.t()} | {:error, reason :: term}
end
