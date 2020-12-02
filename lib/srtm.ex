defmodule SRTM do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  alias __MODULE__.{Client, Error}

  @doc """
  Queries locations on the earth for elevation data.

  If the corresponding file can't be found in the cache, it will be retrieved
  online.

  Returns the elevation in meters.

  **Note:**

  * Make sure to match on the client to always use the latests client struct.
  Otherwise SRTM files will be re-read into memory on every call!

  * The SRTM Files are cached in memory. Querying many coordinates at different
  locations on Earth may therefore take up a lot of memory space. See
  `SRTM.Client.purge_in_memory_cache/2`.

  ## Examples

      iex> {:ok, client} = SRTM.Client.new("./cache")
      iex> {:ok, elevation, client} = SRTM.get_elevation(client, 36.455556, -116.866667)
      iex> elevation
      -51

  """
  @spec get_elevation(client :: Client.t(), latitude :: number, longitude :: number) ::
          {:ok, elevation :: integer | nil, client :: Client.t()} | {:error, error :: Error.t()}
  defdelegate get_elevation(client, latitude, longitude), to: Client
end
