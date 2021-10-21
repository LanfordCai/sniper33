defmodule Sniper33.Repo.Migrations.CreateTweets do
  use Ecto.Migration

  def change do
    create table(:tweets) do
      add :user_id, :string
      add :tweet_id, :string
      add :created_at, :naive_datetime
      add :content, :string

      timestamps()
    end

    create index("tweets", [:tweet_id], unique: true)
    create index("tweets", [:created_at])
  end
end
