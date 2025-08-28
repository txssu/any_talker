# Copied from lib/ex_gram/adapter/tesla.ex
if Code.ensure_loaded?(Tesla) do
  defmodule ExGram.Adapter.TeslaNoDebug do
    @moduledoc """
    HTTP Adapter that uses Tesla
    """

    @behaviour ExGram.Adapter

    use Tesla, only: ~w(get post)a

    alias Tesla.Adapter.Hackney

    require Logger

    @base_url "https://api.telegram.org"

    plug(Tesla.Middleware.BaseUrl, ExGram.Config.get(:ex_gram, :base_url, @base_url))
    plug(Tesla.Middleware.Headers, [{"Content-Type", "application/json"}])

    plug(
      Tesla.Middleware.JSON,
      decode: &__MODULE__.custom_decode/1,
      encode: &__MODULE__.custom_encode/1
    )

    def custom_encode(x), do: ExGram.Encoder.encode(x)
    def custom_decode(x), do: ExGram.Encoder.decode(x, keys: :atoms)

    @impl ExGram.Adapter
    def request(verb, path, body) do
      body = encode_body(body)

      verb
      |> do_request(path, body)
      |> handle_result()
    end

    defp new do
      Tesla.client(custom_middlewares(), http_adapter())
    end

    defp do_request(:get, path, body) do
      do_request(:post, path, body)
    end

    defp do_request(:post, path, body) do
      post(new(), path, body, opts: opts())
    end

    defp handle_result({:ok, %{body: %{ok: true, result: body}, status: status}}) when status in 200..299 do
      {:ok, body}
    end

    defp handle_result({:ok, %{body: body}}) do
      {:error, %ExGram.Error{code: :response_status_not_match, message: encode(body)}}
    end

    defp handle_result({:error, reason}) do
      {:error, %ExGram.Error{code: reason}}
    end

    defp encode_body(body) when is_map(body) do
      Map.new(body, fn {key, value} -> {key, encode(value)} end)
    end

    defp encode_body({:multipart, parts}) do
      mp = Tesla.Multipart.add_content_type_param(Tesla.Multipart.new(), "charset=utf-8")
      Enum.reduce(parts, mp, &add_multipart_part/2)
    end

    defp add_multipart_part({:file, name, path}, mp) do
      Tesla.Multipart.add_file(mp, path, name: name)
    end

    defp add_multipart_part({:file_content, name, content, filename}, mp) do
      Tesla.Multipart.add_file_content(mp, content, filename, name: name)
    end

    defp add_multipart_part({name, value}, mp) do
      Tesla.Multipart.add_field(mp, name, value)
    end

    defp encode(%{__struct__: _struct} = x) do
      x
      |> Map.from_struct()
      |> filter_map()
      |> ExGram.Encoder.encode!()
    end

    defp encode(x) when is_map(x) or is_list(x), do: ExGram.Encoder.encode!(x)
    defp encode(x), do: x

    defp filter_map(%{__struct__: _struct} = m) do
      m
      |> Map.from_struct()
      |> filter_map()
    end

    defp filter_map(m) when is_map(m) do
      m
      |> Enum.filter(fn {_key, value} -> not is_nil(value) end)
      |> Map.new(fn {key, value} ->
        cond do
          is_list(value) -> {key, Enum.map(value, &filter_map/1)}
          is_map(value) -> {key, filter_map(value)}
          true -> {key, value}
        end
      end)
    end

    defp filter_map(m) when is_list(m), do: Enum.map(m, &filter_map/1)
    defp filter_map(m), do: m

    defp http_adapter, do: Application.get_env(:tesla, :adapter) || Hackney

    defp opts, do: [adapter: adapter_opts()]

    defp adapter_opts do
      http_adapter()
      |> extract_adapter_module()
      |> adapter_timeout_options()
    end

    defp extract_adapter_module(module) when is_atom(module), do: module
    defp extract_adapter_module({module, _adapter_opts}), do: module
    defp extract_adapter_module(_unknown_adapter), do: nil

    defp adapter_timeout_options(Hackney) do
      [connect_timeout: 20_000, timeout: 60_000, recv_timeout: 60_000]
    end

    defp adapter_timeout_options(Tesla.Adapter.Finch) do
      [pool_timeout: 20_000, receive_timeout: 60_000]
    end

    defp adapter_timeout_options(Tesla.Adapter.Gun) do
      [connect_timeout: 20_000, timeout: 60_000]
    end

    defp adapter_timeout_options(Tesla.Adapter.Mint) do
      [timeout: 60_000]
    end

    defp adapter_timeout_options(Tesla.Adapter.Httpc) do
      [connect_timeout: 20_000, timeout: 60_000]
    end

    defp adapter_timeout_options(Tesla.Adapter.Ibrowse) do
      [connect_timeout: 20_000, timeout: 60_000]
    end

    defp adapter_timeout_options(_unknown_adapter), do: []

    defp format_middleware({module, function, args}) do
      case apply(module, function, args) do
        {_middleware_name, _middleware_opts} = middleware -> {:ok, middleware}
        _invalid_middleware -> :error
      end
    end

    defp format_middleware({_middleware_name, _middleware_opts} = middleware_tuple), do: {:ok, middleware_tuple}
    defp format_middleware(_invalid_middleware), do: :error

    defp custom_middlewares do
      middlewares = Application.get_env(:ex_gram, __MODULE__, [])[:middlewares] || []

      middlewares
      |> Enum.reduce([], fn elem, acc ->
        case format_middleware(elem) do
          {:ok, middleware} ->
            [middleware | acc]

          :error ->
            Logger.warning("Discarded, element is not a middleware: #{inspect(elem)}")
            acc
        end
      end)
      |> Enum.reverse()
    end
  end
end
