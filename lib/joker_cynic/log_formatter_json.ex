# Copied from LoggerJSON.Formatters.Basic
defmodule JokerCynic.LogFormatterJSON do
  @moduledoc false
  @behaviour LoggerJSON.Formatter

  import LoggerJSON.Formatter.DateTime
  import LoggerJSON.Formatter.MapBuilder
  import LoggerJSON.Formatter.Message
  import LoggerJSON.Formatter.Metadata
  import LoggerJSON.Formatter.RedactorEncoder

  require Jason.Helpers

  @processed_metadata_keys ~w[file line mfa
                              otel_span_id span_id
                              otel_trace_id trace_id
                              conn]a

  @impl true
  def format(%{level: level, meta: meta, msg: msg}, opts) do
    opts = Keyword.new(opts)
    encoder_opts = Keyword.get(opts, :encoder_opts, [])
    metadata_keys_or_selector = Keyword.get(opts, :metadata, [])
    metadata_selector = update_metadata_selector(metadata_keys_or_selector, @processed_metadata_keys)
    redactors = Keyword.get(opts, :redactors, [])

    static_fields = opts |> Keyword.get(:static_fields, %{}) |> Map.new()

    message =
      format_message(msg, meta, %{
        binary: &format_binary_message/1,
        structured: &format_structured_message/1,
        crash: &format_crash_reason(&1, &2, meta)
      })

    line =
      %{
        time: utc_time(meta),
        level: Atom.to_string(level),
        message: message,
        metadata: take_metadata(meta, metadata_selector)
      }
      |> Map.merge(static_fields)
      |> encode(redactors)
      |> maybe_put(:request, format_http_request(meta))
      |> maybe_put(:span, format_span(meta))
      |> maybe_put(:trace, format_trace(meta))
      |> Jason.encode_to_iodata!(encoder_opts)

    [line, "\n"]
  end

  def format_binary_message(binary) do
    IO.chardata_to_string(binary)
  end

  def format_structured_message(map) when is_map(map) do
    map
  end

  def format_structured_message(keyword) do
    Map.new(keyword)
  end

  def format_crash_reason(binary, _reason, _meta) do
    IO.chardata_to_string(binary)
  end

  if Code.ensure_loaded?(Plug.Conn) do
    defp format_http_request(%{conn: %Plug.Conn{} = conn}) do
      Jason.Helpers.json_map(
        connection:
          Jason.Helpers.json_map(
            protocol: Plug.Conn.get_http_protocol(conn),
            method: conn.method,
            path: conn.request_path,
            status: conn.status
          ),
        client:
          Jason.Helpers.json_map(
            user_agent: LoggerJSON.Formatter.Plug.get_header(conn, "user-agent"),
            ip: LoggerJSON.Formatter.Plug.remote_ip(conn)
          )
      )
    end
  end

  defp format_http_request(_meta), do: nil

  defp format_span(%{otel_span_id: otel_span_id}), do: IO.chardata_to_string(otel_span_id)
  defp format_span(%{span_id: span_id}), do: span_id
  defp format_span(_meta), do: nil

  defp format_trace(%{otel_trace_id: otel_trace_id}), do: IO.chardata_to_string(otel_trace_id)
  defp format_trace(%{trace_id: trace_id}), do: trace_id
  defp format_trace(_meta), do: nil
end
