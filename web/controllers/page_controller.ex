defmodule Kaisuu.PageController do
  use Kaisuu.Web, :controller

  def index(conn, _params) do

    # redis.sort("kanji_data", :by => "kanji:*->count", :order => "desc") # => ["2", "1"]
    top_used_kanji_query = ~w(SORT kanji_data BY kanji:*->count DESC)
    {:ok, kanji_data} = Kaisuu.RedisPool.command(top_used_kanji_query)

    {:ok, kanji_data_count} = Kaisuu.RedisPool.command ~w(GET kanji_data_count)

    conn
    |> assign(:kanji_data_count, kanji_data_count)
    |> assign(:kanji_data, kanji_data)
    |> render("index.html")
  end

  defp transform_hex_to_string(hex_code_point) do
    int_code_point = hex_code_point |> String.to_integer(16)
    <<int_code_point :: utf8>>
  end
end
