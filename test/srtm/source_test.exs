defmodule SRTM.SourceTest do
  use SRTM.Case, async: true

  alias SRTM.Source

  describe "name/2" do
    test "returns the HGT file name for the given coordinates" do
      assert "N12W043" = Source.name(12.3456, -42.0001)
      assert "S55E112" = Source.name(-54.321, 112.0001)
    end
  end

  describe "get/2" do
    test "issues a GET request", %{bypass: bypass} do
      Bypass.expect_once(bypass, fn %Plug.Conn{} = conn ->
        assert conn.method == "GET"

        assert {_, "github.com/adriankumpf/srtm"} =
                 List.keyfind(conn.req_headers, "user-agent", 0)

        assert conn.request_path == "/foo"

        Plug.Conn.resp(conn, 200, "ok")
      end)

      assert {:ok, "ok"} = Source.get("http://localhost:#{bypass.port}/foo")
    end

    test "handles connection errors", %{bypass: bypass} do
      Bypass.down(bypass)

      assert {:error, srtm_error} = Source.get("http://localhost:#{bypass.port}/foo")

      reason =
        {:failed_connect,
         [{:to_address, {~c"localhost", bypass.port}}, {:inet, [:inet], :econnrefused}]}

      assert %SRTM.Error{
               reason: reason,
               message: """
               Failed to download HGT file from 'http://localhost:#{bypass.port}/foo' \
               (reason: #{inspect(reason)}).\
               """
             } == srtm_error
    end

    test "handles timeouts", %{bypass: bypass} do
      assert {:error, srtm_error} = Source.get("http://localhost:#{bypass.port}/foo", timeout: 0)

      assert srtm_error.reason in [
               {:failed_connect,
                [{:to_address, {~c"localhost", bypass.port}}, {:inet, [:inet], :timeout}]},
               :timeout
             ]

      assert """
             Failed to download HGT file from 'http://localhost:#{bypass.port}/foo' \
             (reason: #{inspect(srtm_error.reason)}).\
             """ == srtm_error.message
    end
  end
end