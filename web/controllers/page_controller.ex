defmodule Kaisuu.PageController do
  use Kaisuu.Web, :controller

  def index(conn, _params) do

    # redis.sort("kanji_data", :by => "kanji:*->count", :order => "desc") # => ["2", "1"]
    command = ~w(SORT kanji_data BY kanji:*->count DESC GET #)
    {:ok, kanji_data} = Kaisuu.RedisPool.command(command)

    command = kanji_data |> Enum.map(fn(key) -> ~w(HGET kanji:#{key} count) end)
    {:ok, kanji_data_count} = Kaisuu.RedisPool.pipeline(command)

    kanji_data = Enum.zip(kanji_data, kanji_data_count)

    {:ok, kanji_data_total_count} = Kaisuu.RedisPool.command ~w(GET kanji_data_count)

    conn
    |> assign(:kanji_data, kanji_data)
    |> assign(:kanji_data_total_count, kanji_data_total_count)
    |> render("index.html")
  end

  defp transform_hex_to_string(hex_code_point) do
    int_code_point = hex_code_point |> String.to_integer(16)
    <<int_code_point :: utf8>>
  end
end
