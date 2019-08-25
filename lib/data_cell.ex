defmodule Srtm.DataCell do
  import Bitwise

  defstruct [:hgt_data, :latitude, :longitude, :points_per_cell]

  @srtm_3 1201 * 1201 * 2
  @srtm_1 3601 * 3601 * 2

  def from_file!(path) do
    hgt_data = File.read!(path)

    ppc =
      case byte_size(hgt_data) do
        @srtm_3 -> 1201
        @srtm_1 -> 3601
      end

    {lat, lng} =
      path
      |> Path.basename(".hgt")
      |> reverse_coordinates()

    %__MODULE__{hgt_data: hgt_data, latitude: lat, longitude: lng, points_per_cell: ppc}
  end

  def get_elevation(%__MODULE__{points_per_cell: ppc} = dc, lat, lng) do
    local_lat = trunc((lat - dc.latitude) * ppc)
    local_lng = trunc((lng - dc.longitude) * ppc)

    byte_pos = (ppc - local_lat - 1) * ppc * 2 + local_lng * 2

    cond do
      byte_pos < 0 or byte_pos > ppc * ppc * 2 ->
        raise "Coordinates out of range"

      byte_pos >= byte_size(dc.hgt_data) ->
        nil

      :binary.at(dc.hgt_data, byte_pos) == 0x80 && :binary.at(dc.hgt_data, byte_pos + 1) == 0x00 ->
        nil

      true ->
        :binary.at(dc.hgt_data, byte_pos) <<< 8 ||| :binary.at(dc.hgt_data, byte_pos + 1)
    end
  end

  defp reverse_coordinates(<<d0::size(8), lat::size(16), d1::size(8), lng::size(24)>>) do
    lat = String.to_integer(<<lat::size(16)>>)
    lng = String.to_integer(<<lng::size(24)>>)

    lat = if d0 == ?S, do: lat * -1, else: lat
    lng = if d1 == ?W, do: lng * -1, else: lng

    {lat, lng}
  end
end
