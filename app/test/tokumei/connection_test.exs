defmodule Tokumei.ConnectionTest do
  use ExUnit.Case

  alias Raxx.Response
  alias Raxx.Request

  use Tokumei.Connection

  def handle_request(%{method: :GET}, _), do: Response.ok("GET")

  test "sends back connection: close if that was received" do
    response = Request.get("/", nil, [{"connection", "close"}]) |> handle_request(:config)

    assert [{"connection", "close"}] == response.headers
  end

  test "does not send back connection: close if not received" do
    response = Request.get("/", nil, []) |> handle_request(:config)

    assert [] == response.headers
  end

  test "will close client connection if request is a close request" do
    {:ok, endpoint} = Ace.HTTP.start_link({__MODULE__, :none}, port: 0)
    {:ok, port} = Ace.HTTP.port(endpoint)
    # DEBT remove this sleep, the endpoint should only be ready once listening
    Process.sleep(1_000)

    request = """
    GET / HTTP/1.1
    host: localhost:#{port}
    connection: close

    """
    {:ok, connection} = :gen_tcp.connect('localhost', port, [active: true, mode: :binary])
    :ok = :gen_tcp.send(connection, request)

    assert_receive {:tcp, ^connection, response}, 1_000
    assert String.contains?(response, "connection: close")
    assert_receive {:tcp_closed, ^connection}, 3_000
  end
end
