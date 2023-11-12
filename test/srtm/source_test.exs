defmodule SRTM.SourceTest do
  use SRTM.Case, async: true

  alias SRTM.Source

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

    test "handles timeouts", %{bypass: %{port: port} = bypass} do
      Bypass.down(bypass)

      assert {:error, srtm_error} =
               Source.get("http://localhost:#{bypass.port}/foo", timeout: 0)

      assert {:failed_connect, [{:to_address, {~c"localhost", ^port}}, _]} =
               srtm_error.reason

      assert """
             Failed to download HGT file from 'http://localhost:#{bypass.port}/foo' \
             (reason: #{inspect(srtm_error.reason)}).\
             """ == srtm_error.message
    end
  end
end
