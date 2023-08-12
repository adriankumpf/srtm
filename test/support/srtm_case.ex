defmodule SRTM.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      ExUnit.Case.register_attribute(__MODULE__, :sources)

      @moduletag :tmp_dir

      import SRTM.Case
    end
  end

  setup %{tmp_dir: tmp_dir, registered: registered} do
    bypass = Bypass.open()

    client_opts =
      if sources = registered.sources do
        [sources: Enum.map(sources, &{&1, endpoint: "http://localhost:#{bypass.port}"})]
      else
        []
      end

    {:ok, client} = SRTM.Client.new(tmp_dir, client_opts)

    %{client: client, bypass: bypass}
  end

  def expect_hgt_download(bypass, response \\ nil) do
    Bypass.expect_once(bypass, fn %Plug.Conn{method: "GET"} = conn ->
      {status, body} = response || {200, File.read!(Path.join("test/data", conn.request_path))}
      Plug.Conn.resp(conn, status, body)
    end)

    bypass
  end
end
