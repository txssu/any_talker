defmodule AnyTalkerBot.Config.EmbedDomains do
  @moduledoc """
  Configuration for domain replacements to create embedded link previews.

  This module provides mapping between regular domains and their embedded preview versions.
  """

  @domain_mapping %{
    "x.com" => "fixupx.com",
    "twitter.com" => "fxtwitter.com",
    "instagram.com" => "kkinstagram.com",
    "reddit.com" => "rxddit.com",
    "tiktok.com" => "vxtiktok.com"
  }

  @doc """
  Returns the domain mapping for embedded previews.

  ## Example

      EmbedDomains.domain_mapping()
      # => %{"x.com" => "fixup.com", ...}
  """
  def domain_mapping, do: @domain_mapping

  @doc """
  Replaces a domain with its embedded version if supported.

  Returns the embedded domain if found in mapping, otherwise returns the original domain.
  Automatically handles www. prefix by removing it before lookup.

  ## Example

      EmbedDomains.replace_domain("x.com")
      # => "fixup.com"

      EmbedDomains.replace_domain("www.instagram.com")
      # => "kkinstagram.com"

      EmbedDomains.replace_domain("unknown.com")
      # => "unknown.com"
  """
  def replace_domain(domain) when is_binary(domain) do
    normalized = normalize_domain(domain)
    Map.get(@domain_mapping, normalized, domain)
  end

  defp normalize_domain("www." <> rest), do: rest
  defp normalize_domain(domain), do: domain
end
