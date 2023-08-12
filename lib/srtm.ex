defmodule SRTM do
  @moduledoc """
  A simple interface to query locations on the Earth for elevation data from the NASA Shuttle Radar
  Topography Mission (SRTM).
  """

  alias __MODULE__.{Client, Error}

  @typedoc """
  A geographic coordinate that specifies the north–south position of a point on the surface of the
  Earth.
  """
  @type latitude :: number()

  @typedoc """
  A geographic coordinate that specifies the east–west position of a point on the surface of the
  Earth.
  """
  @type longitude :: number()

  @typedoc "Elevation (in meters)"
  @type elevation :: integer()

  @doc """
  Queries locations on the earth for elevation data.

  If the corresponding file can't be found in the cache, it will be retrieved online.

  Returns the elevation in meters.

  ## Note

  * Make sure to match on the client to always use the latests client struct. Otherwise the SRTM
    files will be re-read into memory on every call!

  * The SRTM files are cached in memory. Querying many coordinates at different locations may
    therefore take up a lot of memory space. See `SRTM.Client.purge_in_memory_cache/2`.

  ## Examples

      iex> {:ok, client} = SRTM.Client.new("./cache")
      iex> {:ok, elevation, client} = SRTM.get_elevation(client, 36.455556, -116.866667)
      {:ok, -51, %SRTM.Client{}}

  """
  @spec get_elevation(Client.t(), latitude, longitude) ::
          {:ok, elevation | nil, Client.t()} | {:error, Error.t()}
  defdelegate get_elevation(client, latitude, longitude), to: Client
end
