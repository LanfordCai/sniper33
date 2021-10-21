defmodule Sniper33.Twitter.Tweet do
  @moduledoc false

  use Ecto.Schema

  import Ecto.{Changeset, Query}

  alias Sniper33.Repo

  schema "tweets" do
    field :user_id, :string
    field :tweet_id, :string
    field :created_at, :naive_datetime
    field :content, :string

    timestamps()
  end

  def new!(user_id, %{
        "created_at" => created_at,
        "id" => tweet_id,
        "text" => content
      }) do
    %__MODULE__{}
    |> changeset(%{
      user_id: user_id,
      tweet_id: tweet_id,
      created_at: NaiveDateTime.from_iso8601!(created_at),
      content: content
    })
    |> Repo.insert!()
  end

  @required_fields ~w(user_id tweet_id created_at content)a
  def changeset(tweet, params \\ %{}) do
    tweet
    |> cast(params, @required_fields)
    |> unique_constraint(
      :tweet_id,
      name: :tweets_tweet_id_index
    )
  end

  def latest(user_id) do
    __MODULE__
    |> where(user_id: ^user_id)
    |> order_by(desc: :tweet_id)
    |> limit(1)
    |> Repo.one()
  end

  def in_hours(user_id, hours) do
    gap = -1 * hours

    __MODULE__
    |> where([t], t.user_id == ^user_id and t.created_at > from_now(^gap, "hour"))
    |> order_by(desc: :tweet_id)
    |> Repo.all()
  end
end
