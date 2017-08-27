defmodule Tokumei.Connection do
  @moduledoc """
  If we respond to a request with Connection: close, we should send a response
  back with Connection: close and then close it ourselves.

  This works around buggy clients that send Connection: close and never close the
  connection themselves.

  # TODO should check version HTTP/1 or 1.1 to decide default behaviour when connection header absent
  """

  defmacro __using__(_opts) do
    quote do
      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote location: :keep do
      defoverridable [handle_request: 2]

      def handle_request(request, env) do
        response = super(request, env)

        new_response = case Raxx.Connection.fetch(request) do
          {:ok, "close"} ->
            if :proplists.is_defined("connection", response.headers) do
              response
            else
              Raxx.Connection.set(response, "close")
            end
          _ ->
            response
        end

        case Raxx.Connection.fetch(request) do
          {:ok, "close"} ->
            Process.send_after(self(), :close_timeout, 1_000)
          _ ->
            :ok
        end

        new_response
      end

      # defoverridable [handle_info: 2]
      def handle_info(a, b) do
        IO.inspect(a)
      end
    end
  end
end
