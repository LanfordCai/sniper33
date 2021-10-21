defmodule Sniper33 do
  @moduledoc """
  Sniper33 keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  use Supervisor

  alias Sniper33.Twitter.Syncer
  alias Sniper33.Discord.Poster

  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    user_id = Application.get_env(:sniper33, :twitter_user_id)

    children = [
      {Syncer, user_id},
      {Poster, user_id}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
