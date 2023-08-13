defmodule SRTM.Source do
  @moduledoc """
  Specifies the API for using a custom SRTM dataset source.
  """

  @type coordinates :: {SRTM.latitude(), SRTM.longitude()}
  @type opts :: keyword()

  @doc """
  Downloads the HGT file for the given coordinates and stores it under the given
  `client.cache_path`.

  If successful, returns an ok tuple with the path to the file. Otherwise returns an error tuple
  with an `SRTM.Error.t()` or `:out_of_bounds`.
  """
  @callback fetch(SRTM.Client.t(), coordinates, opts()) ::
              {:ok, Path.t()} | {:error, SRTM.Error.t() | :out_of_bounds}

  defmacro __using__(_opts) do
    quote do
      @behaviour SRTM.Source

      import SRTM.Source
    end
  end

  @doc false
  def name(lat, lng) do
    if(lat >= 0, do: "N", else: "S") <>
      (lat |> floor() |> abs() |> pad(2)) <>
      if(lng >= 0, do: "E", else: "W") <>
      (lng |> floor() |> abs() |> pad(3))
  end

  defp pad(num, count), do: num |> Integer.to_string() |> String.pad_leading(count, "0")

  @doc false
  def get(url, opts \\ []) do
    Application.ensure_all_started(:ssl)
    Application.ensure_all_started(:httpc)
    Application.ensure_all_started(:inets)

    headers = [
      {~c"Host", String.to_charlist(URI.parse(url).host)},
      {~c"User-Agent", ~c"github.com/adriankumpf/srtm"}
    ]

    # All header names and values MUST be charlists in older OTP versions. In newer versions,
    # binaries are fine. This is hard to debug because httpc simply *hangs* on older OTP
    # versions if you use a binary value.
    if Enum.any?(headers, fn {_, val} -> not is_list(val) end) do
      raise "all header names and values must be charlists"
    end

    request = {String.to_charlist(url), headers}

    http_options = [
      timeout: opts[:timeout] || 60_000,
      ssl:
        [
          verify: :verify_peer,
          depth: 3,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
          # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
        ] ++ cacert_option()
    ]

    case :httpc.request(:get, request, http_options, sync: true, body_format: :binary) do
      {:ok, {{_protocol, status_code, _status_message}, _headers, body}}
      when status_code in 200..299 ->
        {:ok, body}

      {:ok, {{_protocol, status_code, _status_message}, _headers, body}} ->
        message =
          "Failed to download HGT file from '#{url}' " <>
            "(reason: status_code = #{status_code}, body = #{body})."

        {:error, %SRTM.Error{reason: :download_failed, message: message}}

      {:error, reason} ->
        message = "Failed to download HGT file from '#{url}' (reason: #{inspect(reason)})."
        {:error, %SRTM.Error{reason: reason, message: message}}
    end
  end

  if System.otp_release() >= "25" do
    defp cacert_option do
      if Code.ensure_loaded?(CAStore) do
        [cacertfile: String.to_charlist(CAStore.file_path())]
      else
        case :public_key.cacerts_load() do
          :ok ->
            [cacerts: :public_key.cacerts_get()]

          {:error, reason} ->
            raise SRTM.Error,
              message: """
              Failed to load OS certificates. We tried to use OS certificates because we
              couldn't find the :castore library. If you want to use :castore, please add
                {:castore, "~> 1.0"}
              to your dependencies. Otherwise, make sure you can load OS certificates by
              running :public_key.cacerts_load() and checking the result. The error we
              got was:
                #{inspect(reason)}
              """
        end
      end
    end
  else
    defp cacert_option do
      if Code.ensure_loaded?(CAStore) do
        [cacertfile: String.to_charlist(CAStore.file_path())]
      else
        raise SRTM.Error,
          message: """
          Failed to use any SSL certificates. We didn't find the :castore library,
          and we couldn't use OS certificates because that requires OTP 25 or later.
          If you want to use :castore, please add
            {:castore, "~> 1.0"}
          """
      end
    end
  end
end
