defmodule SRTM do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias __MODULE__.Client

  @doc """
  Queries locations on the earth for elevation data.

  If the corresponding file can't be found in the cache, it will be retrieved
  online.

  Returns the elevation in meters.

  **Note:**

  * Make sure to match on the client to always use the latests client struct.
  Otherwise SRTM files will be re-downloaded on every call!

  * The SRTM Files are cached in memory. Querying many coordinates at different
  locations on Earth may therefore take up a lot of memory space.

  ## Examples

      iex> {:ok, elevation, client} = SRTM.get_elevation(client, 36.455556, -116.866667)
      {:ok, -51, %SRTM.client{}}

  """
  @spec get_elevation(client :: Client.t(), latitude :: float, longitude :: float) ::
          {:ok, elevation :: float, client :: Client.t()} | {:error, reason :: term}
  defdelegate get_elevation(client, latitude, longitude), to: Client
end
