defmodule Sniper33.Utils do
  @moduledoc false

  require Logger

  def extract_value("$" <> value) do
    {num, unit} = String.split_at(value, String.length(value) - 1)

    case unit do
      "K" ->
        Decimal.new(num) |> Decimal.mult(1000)

      "M" ->
        Decimal.new(num) |> Decimal.mult(1_000_000)

      "B" ->
        Decimal.new(num) |> Decimal.mult(1_000_000_000)

      otherwise ->
        Logger.error("[Sniper33] unknown unit #{otherwise} detected")
        raise "unknown unit"
    end
  end
end
