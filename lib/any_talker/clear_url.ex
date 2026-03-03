defmodule AnyTalker.ClearUrl do
  @moduledoc """
  Removes tracking parameters from URLs using ClearURLs rules.

  Rules are compiled from ClearURLs/Rules `data.min.json` at compile time.
  Each provider has:
  - `url_pattern` — regex to match URLs this provider handles
  - `rules` — query parameter name patterns to remove
  - `raw_rules` — patterns applied to the full URL string
  - `exceptions` — URLs that should be skipped even if `url_pattern` matches
  - `complete_provider` — if true, the entire provider is a blocker (skip)

  ## Examples

      iex> AnyTalker.ClearUrl.clean("https://example.com/page?utm_source=twitter&id=1")
      "https://example.com/page?id=1"

      iex> AnyTalker.ClearUrl.clean("https://example.com/page")
      "https://example.com/page"
  """

  @external_resource Path.join(Mix.Project.deps_paths().clearurl_rules, "data.min.json")

  @providers Mix.Project.deps_paths().clearurl_rules
             |> Path.join("data.min.json")
             |> File.read!()
             |> Jason.decode!()
             |> Map.get("providers", %{})
             |> Enum.reject(fn {_name, config} -> config["completeProvider"] == true end)
             |> Enum.map(fn {_name, config} ->
               %{
                 url_pattern: Regex.compile!(config["urlPattern"], "i"),
                 rules: Enum.map(config["rules"] || [], &Regex.compile!("^#{&1}$", "i")),
                 raw_rules: Enum.map(config["rawRules"] || [], &Regex.compile!(&1, "i")),
                 exceptions: Enum.map(config["exceptions"] || [], &Regex.compile!(&1, "i")),
                 referral_marketing: Enum.map(config["referralMarketing"] || [], &Regex.compile!("^#{&1}$", "i"))
               }
             end)

  @doc """
  Removes tracking parameters from the given URL.

  Returns the cleaned URL string. If the URL doesn't match any provider
  or parsing fails, returns it unchanged.

  ## Examples

      iex> AnyTalker.ClearUrl.clean("https://www.amazon.com/dp/B01N5IB20Q?tag=foo&ref=bar&qid=123")
      "https://www.amazon.com/dp/B01N5IB20Q"

      iex> AnyTalker.ClearUrl.clean("not-a-url")
      "not-a-url"
  """
  def clean(url) when is_binary(url) do
    @providers
    |> Enum.filter(fn provider ->
      Regex.match?(provider.url_pattern, url) and not exception?(url, provider)
    end)
    |> Enum.reduce(url, &apply_rules(&2, &1))
  end

  defp exception?(url, provider) do
    Enum.any?(provider.exceptions, &Regex.match?(&1, url))
  end

  defp apply_rules(url, provider) do
    url
    |> remove_query_params(provider.rules ++ provider.referral_marketing)
    |> apply_raw_rules(provider.raw_rules)
  end

  defp remove_query_params(url, []), do: url

  defp remove_query_params(url, param_patterns) do
    uri = URI.parse(url)

    case uri.query do
      nil ->
        url

      query ->
        cleaned =
          query
          |> URI.decode_query()
          |> Enum.reject(fn {key, _value} ->
            Enum.any?(param_patterns, &Regex.match?(&1, key))
          end)
          |> URI.encode_query()

        uri
        |> Map.put(:query, if(cleaned == "", do: nil, else: cleaned))
        |> URI.to_string()
    end
  end

  defp apply_raw_rules(url, []), do: url

  defp apply_raw_rules(url, raw_rules) do
    Enum.reduce(raw_rules, url, fn pattern, acc ->
      Regex.replace(pattern, acc, "")
    end)
  end
end
