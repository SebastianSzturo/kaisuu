defmodule Kaisuu.KanjiChannel do
  use Phoenix.Channel

  def join("kanji:all", _message, socket) do
    {:ok, socket}
  end
  def join("kanji:" <> _private_room_id, _params, _socket) do
    {:error, %{reason: "unauthorized"}}
  end

  def handle_in("new_kanji", %{"body" => body}, socket) do
    broadcast! socket, "new_kanji", %{body: body}
    {:noreply, socket}
  end

  def handle_out("new_kanji", payload, socket) do
    push socket, "new_kanji", payload
    {:noreply, socket}
  end
end
