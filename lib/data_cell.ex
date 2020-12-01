defmodule SRTM.DataCell do
  @moduledoc false

  alias SRTM.Error

  defstruct [:hgt_data, :latitude, :longitude, :points_per_cell, :last_used]

  def from_file(path) do
    with {:ok, hgt_data} <- read(path),
         {:ok, ppc} <- get_ppc(hgt_data) do
      {lat, lng} =
        path
        |> Path.basename(".hgt")
        |> reverse_coordinates()

      data_cell = %__MODULE__{
        hgt_data: hgt_data,
        latitude: lat,
        longitude: lng,
        points_per_cell: ppc
      }

      {:ok, data_cell}
    end
  end

  def get_elevation(%__MODULE__{points_per_cell: ppc, hgt_data: hgt_data} = dc, lat, lng) do
    row = trunc((dc.latitude + 1 - lat) * (ppc - 1))
    col = trunc((lng - dc.longitude) * (ppc - 1))
    byte_pos = (row * ppc + col) * 2

    cond do
      byte_pos < 0 or byte_pos > ppc * ppc * 2 ->
        raise "Coordinates out of range"

      byte_pos >= byte_size(hgt_data) ->
        nil

      :binary.at(hgt_data, byte_pos) == 0x80 && :binary.at(hgt_data, byte_pos + 1) == 0x00 ->
        nil

      true ->
        hgt_data
        |> binary_part(byte_pos, 2)
        |> decode_elevation()
    end
  end

  defp decode_elevation(<<val::signed-big-integer-size(16)>>) when val in -1000..10000, do: val
  defp decode_elevation(_binary), do: nil

  defp reverse_coordinates(<<d0::size(8), lat::size(16), d1::size(8), lng::size(24)>>) do
    lat = String.to_integer(<<lat::size(16)>>)
    lng = String.to_integer(<<lng::size(24)>>)

    lat = if d0 == ?S, do: lat * -1, else: lat
    lng = if d1 == ?W, do: lng * -1, else: lng

    {lat, lng}
  end

  defp read(path) do
    with {:error, reason} <- File.read(path) do
      {:error,
       %Error{reason: :io_error, message: "Reading of HGT file failed: #{inspect(reason)}"}}
    end
  end

  @srtm_3 1201 * 1201 * 2
  @srtm_1 3601 * 3601 * 2

  defp get_ppc(hgt_data) do
    case byte_size(hgt_data) do
      @srtm_3 -> {:ok, 1201}
      @srtm_1 -> {:ok, 3601}
      _ -> {:error, %Error{reason: :unkown_file_type, message: "File type unkown"}}
    end
  end
end
