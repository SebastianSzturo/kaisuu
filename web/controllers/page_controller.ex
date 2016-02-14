defmodule Kaisuu.PageController do
  use Kaisuu.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
