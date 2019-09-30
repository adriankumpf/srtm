defmodule SRTM.Source do
  @moduledoc false

  @callback fetch(client :: SRTM.Client.t(), {float, float}) ::
              {:ok, hgt_path :: Path.t()} | {:error, reason :: term}

  defmacro __using__([]) do
    quote do
      @behaviour SRTM.Source

      alias SRTM.Error

      defp name(lat, lng) do
        if(lat >= 0, do: "N", else: "S") <>
          (lat |> floor() |> abs() |> pad(2)) <>
          if(lng >= 0, do: "E", else: "W") <>
          (lng |> floor() |> abs() |> pad(3))
      end

      defp get(client, url) do
        case Tesla.get(client, url) do
          {:ok, %Tesla.Env{status: 200, body: body}} ->
            {:ok, body}

          {:ok, %Tesla.Env{status: status, body: body}} ->
            {:error,
             %Error{
               reason: :download_failed,
               message: "HGT file download failed: #{status} – #{body}"
             }}

          {:error, reason} ->
            {:error, %Error{reason: reason, message: "HTTP request failed"}}
        end
      end

      defp pad(num, count) do
        num |> Integer.to_string() |> String.pad_leading(count, "0")
      end
    end
  end
end
