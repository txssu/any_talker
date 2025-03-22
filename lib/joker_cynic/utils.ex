defmodule JokerCynic.Utils do
  @moduledoc false

  def parse_proxy_config(nil), do: nil

  def parse_proxy_config(string) do
    with %{host: host, port: port, scheme: scheme} <- URI.parse(string),
         {:ok, scheme_atom} <- safe_to_atom(scheme) do
      {scheme_atom, host, port, []}
    end
  end

  defp safe_to_atom(string) do
    {:ok, String.to_existing_atom(string)}
  rescue
    _error -> :error
  end
end
