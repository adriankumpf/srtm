defmodule SRTM.ClientTest do
  use SRTM.Case, async: true

  alias SRTM.Client

  describe "purge_in_memory_cache/2" do
    @data_cells %{
      {-84, 3} =>
        {:ok,
         %SRTM.DataCell{
           hgt_data: <<0>>,
           latitude: -84,
           longitude: 3,
           points_per_cell: 3601,
           last_used: ~U[2023-08-12 23:30:00.000000Z]
         }},
      {-64, -58} =>
        {:ok,
         %SRTM.DataCell{
           hgt_data: <<0>>,
           latitude: -64,
           longitude: -58,
           points_per_cell: 3601,
           last_used: ~U[2023-08-12 23:00:00.000000Z]
         }},
      {-57, -58} =>
        {:ok,
         %SRTM.DataCell{
           hgt_data: <<0>>,
           latitude: -57,
           longitude: -58,
           points_per_cell: 3601,
           last_used: ~U[2023-08-12 23:19:00.000000Z]
         }},
      {-56, -68} =>
        {:ok,
         %SRTM.DataCell{
           hgt_data: <<0>>,
           latitude: -56,
           longitude: -68,
           points_per_cell: 3601,
           last_used: ~U[2023-08-12 23:29:00.000000Z]
         }},
      {-49, 68} =>
        {:ok,
         %SRTM.DataCell{
           hgt_data: <<0>>,
           latitude: -49,
           longitude: 68,
           points_per_cell: 3601,
           last_used: ~U[2023-08-10 10:00:00.000000Z]
         }},
      {-27, 146} =>
        {:ok,
         %SRTM.DataCell{
           hgt_data: <<0>>,
           latitude: -27,
           longitude: 146,
           points_per_cell: 3601,
           last_used: ~U[2023-08-12 23:30:01.000000Z]
         }},
      {-13, -78} =>
        {:ok,
         %SRTM.DataCell{
           hgt_data: <<0>>,
           latitude: -13,
           longitude: -78,
           points_per_cell: 3601,
           last_used: ~U[2023-08-12 22:35:00.000000Z]
         }}
    }

    setup %{client: client} do
      %{client: put_in(client.data_cells, @data_cells)}
    end

    test "purges all data cells by default", %{client: client} do
      assert {:ok, client} = Client.purge_in_memory_cache(client)
      assert client.data_cells == %{}
    end

    test "keeps the N most recent data cells", %{client: client} do
      assert {:ok, client} = Client.purge_in_memory_cache(client, keep: 3)

      assert client.data_cells == %{
               {-84, 3} =>
                 {:ok,
                  %SRTM.DataCell{
                    hgt_data: <<0>>,
                    latitude: -84,
                    longitude: 3,
                    points_per_cell: 3601,
                    last_used: ~U[2023-08-12 23:30:00.000000Z]
                  }},
               {-56, -68} =>
                 {:ok,
                  %SRTM.DataCell{
                    hgt_data: <<0>>,
                    latitude: -56,
                    longitude: -68,
                    points_per_cell: 3601,
                    last_used: ~U[2023-08-12 23:29:00.000000Z]
                  }},
               {-27, 146} =>
                 {:ok,
                  %SRTM.DataCell{
                    hgt_data: <<0>>,
                    latitude: -27,
                    longitude: 146,
                    points_per_cell: 3601,
                    last_used: ~U[2023-08-12 23:30:01.000000Z]
                  }}
             }
    end
  end
end
