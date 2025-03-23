defmodule JokerCynic.Utils do
  @moduledoc false

  @spec parse_proxy_config(nil | String.t()) ::
          nil | {scheme :: atom(), host :: String.t(), port :: integer(), keyword()}
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

  @spec get_env_and_transform(String.t(), (String.t() -> result)) :: result
        when result: any()
  def get_env_and_transform(name, transformer) do
    if value = System.get_env(name) do
      transformer.(value)
    end
  end
end
