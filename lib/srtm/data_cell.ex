defmodule SRTM.DataCell do
  @moduledoc """
  A parsed HGT file.

  `SRTM.Cache` implementations use `new/2` to parse a cached HGT file and `to_binary/1` to
  serialize one.
  """

  alias SRTM.Error

  @opaque t :: %__MODULE__{
            hgt_data: binary(),
            latitude: integer(),
            longitude: integer(),
            points_per_cell: pos_integer()
          }

  defstruct [:hgt_data, :latitude, :longitude, :points_per_cell]

  # HGT files are square grids of big-endian, signed 16-bit samples: 1201² for SRTM-3
  # (3 arc-seconds) and 3601² for SRTM-1 (1 arc-second).
  @srtm3_byte_size 1201 * 1201 * 2
  @srtm1_byte_size 3601 * 3601 * 2

  @doc """
  Parses `data`, the contents of the HGT file `name` (for example `"N36W117"`).
  """
  @spec new(String.t(), binary()) :: {:ok, t} | {:error, Error.t()}
  def new(name, data) do
    with {:ok, points_per_cell} <- points_per_cell(data) do
      {latitude, longitude} = parse_name(name)

      data_cell = %__MODULE__{
        hgt_data: data,
        latitude: latitude,
        longitude: longitude,
        points_per_cell: points_per_cell
      }

      {:ok, data_cell}
    end
  end

  @doc """
  Returns the contents of the HGT file the data cell was parsed from.
  """
  @spec to_binary(t) :: binary()
  def to_binary(%__MODULE__{hgt_data: hgt_data}), do: hgt_data

  @doc false
  def get_elevation(%__MODULE__{} = data_cell, latitude, longitude) do
    %{hgt_data: hgt_data, points_per_cell: ppc, latitude: lat, longitude: lng} = data_cell

    row = trunc((lat + 1 - latitude) * (ppc - 1))
    col = trunc((longitude - lng) * (ppc - 1))
    byte_pos = (row * ppc + col) * 2

    if byte_pos >= 0 and byte_pos < byte_size(hgt_data) do
      hgt_data |> binary_part(byte_pos, 2) |> decode_elevation()
    end
  end

  # Voids are encoded as -32768. Samples outside the range of the Earth's terrain are treated as
  # voids as well, since they can only stem from corrupt data.
  defp decode_elevation(<<val::signed-big-integer-size(16)>>) when val in -1000..10000, do: val
  defp decode_elevation(_binary), do: nil

  defp parse_name(<<ns, latitude::binary-size(2), ew, longitude::binary-size(3)>>) do
    {sign(ns) * String.to_integer(latitude), sign(ew) * String.to_integer(longitude)}
  end

  defp sign(hemisphere) when hemisphere in [?S, ?W], do: -1
  defp sign(_hemisphere), do: 1

  defp points_per_cell(hgt_data) do
    case byte_size(hgt_data) do
      @srtm3_byte_size -> {:ok, 1201}
      @srtm1_byte_size -> {:ok, 3601}
      _ -> {:error, %Error{reason: :unknown_file_type, message: "File type unknown"}}
    end
  end
end
