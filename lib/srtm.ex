defmodule Srtm do
  @moduledoc """
  Documentation for Srtm.
  """

  alias __MODULE__.Client

  @doc """
  Hello world.

  ## Examples

      iex> Srtm.get_elevation(client, 0.0, 0.0)
      :world

  """
  defdelegate get_elevation(client, latitude, longitude), to: Client
end
