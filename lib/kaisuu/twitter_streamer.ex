defmodule Kaisuu.TwitterStreamer do
  use GenServer
  require Logger

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(state) do
    send(self, :start_streaming)

    {:ok, state}
  end

  def handle_info(:start_streaming, state) do
    spawn_link fn ->
      # Coordinates for most of Japan
      japan = "129.484177, 30.923179, 145.985641, 45.799878"

      stream = ExTwitter.stream_filter(locations: japan, language: "ja")
      |> Stream.map(fn(tweet) -> tweet.text end)
      |> Stream.map(fn(text) -> remove_non_kanji_characters(text) end)
      |> Stream.flat_map(fn(text) -> extract_kanji(text) end)
      |> Stream.map(fn(kanji) -> broadcast(kanji) end)
      Enum.to_list(stream)
    end

    {:noreply, state}
  end

  defp remove_non_kanji_characters(text) do
    non_kanji_regex = ~r/[^\x{4e00}-\x{9fff}]+/u
    Regex.replace(non_kanji_regex, text, "")
  end

  defp extract_kanji(text) do
    String.codepoints(text)
    |> Enum.uniq
  end

  defp broadcast(kanji) do
    Kaisuu.Endpoint.broadcast! "kanji:all", "new_kanji", %{ body: kanji }
    {:ok}
  end
end
