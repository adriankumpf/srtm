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

    opts = [disk_cache_path: tmp_dir]

    opts =
      if registered.sources do
        sources = Enum.map(registered.sources, &{&1, endpoint: "http://localhost:#{bypass.port}"})
        Keyword.put(opts, :sources, sources)
      else
        opts
      end

    %{opts: opts, bypass: bypass}
  end

  def expect_hgt_download(bypass, response \\ nil) do
    Bypass.expect_once(bypass, fn %Plug.Conn{method: "GET"} = conn ->
      {status, body} = response || {200, File.read!(Path.join("test/data", conn.request_path))}
      Plug.Conn.resp(conn, status, body)
    end)

    bypass
  end
end
