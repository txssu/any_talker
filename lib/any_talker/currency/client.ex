defmodule AnyTalker.Currency.Client do
  @moduledoc """
  Tesla client for fetching currency exchange rates from the fawazahmed0 currency API.

  ## Usage

      iex> AnyTalker.Currency.Client.get_currencies("usd")
      {:ok, %{"eur" => 0.85, "gbp" => 0.73, ...}}

      iex> AnyTalker.Currency.Client.get_currencies("invalid")
      {:error, :not_found}
  """

  @base_url "https://cdn.jsdelivr.net/npm/@fawazahmed0"

  defp client do
    Tesla.client([
      {Tesla.Middleware.BaseUrl, @base_url},
      Tesla.Middleware.JSON
    ])
  end

  @doc """
  Fetches currency exchange rates for the given currency code.

  Returns a map of currency codes to exchange rates, or an error tuple.

  ## Parameters

    * `currency_code` - The base currency code (e.g., "usd", "eur")

  ## Returns

    * `{:ok, rates}` - Map of currency codes to exchange rates
    * `{:error, reason}` - Error tuple with reason
  """
  @spec get_currencies(String.t()) :: {:ok, map()} | {:error, atom()}
  def get_currencies(currency_code) do
    today = Date.to_iso8601(Date.utc_today())
    path = "currency-api@#{today}/v1/currencies/#{currency_code}.json"

    case Tesla.get(client(), path) do
      {:ok, %Tesla.Env{status: 200, body: body}} ->
        {:ok, body[currency_code]}

      {:ok, %Tesla.Env{status: 404}} ->
        {:error, :not_found}

      {:ok, %Tesla.Env{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  end
end
