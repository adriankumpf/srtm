defmodule SRTM.Source do
  @moduledoc """
  Specifies the API for using a custom SRTM dataset source.
  """

  @callback fetch(SRTM.Client.t(), {SRTM.latitude(), SRTM.longitude()}) ::
              {:ok, Path.t()} | {:error, SRTM.Error.t()}

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

  @doc false
  def get(client, url) do
    case Tesla.get(client, url) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body}

      {:ok, %Tesla.Env{status: status, body: body}} ->
        message = "HGT file download failed: #{status} – #{body}"
        {:error, %SRTM.Error{reason: :download_failed, message: message}}

      {:error, reason} ->
        {:error, %SRTM.Error{reason: reason, message: "HTTP request failed"}}
    end
  end

  defp pad(num, count), do: num |> Integer.to_string() |> String.pad_leading(count, "0")
end
