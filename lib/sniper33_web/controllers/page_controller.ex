defmodule Sniper33Web.PageController do
  use Sniper33Web, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
