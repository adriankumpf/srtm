defmodule Srtm do
  @moduledoc """
  An Elixir library for working with Stripe.
  """

  alias __MODULE__.Client

  @doc """
  Queries locations on the earth for elevation data.

  If the file can't be found in the cache, it will be retrieved from the
  server.

  ## Examples

      iex> Srtm.get_elevation(client, 36.455556,-116.866667)
      {:ok, -51, %Srtm.Client{}}

  """
  defdelegate get_elevation(client, latitude, longitude), to: Client
end
