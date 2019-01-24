defmodule Raxx.BasicAuthenticationTest do
  use ExUnit.Case
  import Raxx
  import Raxx.BasicAuthentication
  doctest Raxx.BasicAuthentication

  alias Raxx.Server

  defmodule SimpleApp do
    use Raxx.SimpleServer

    @impl Raxx.SimpleServer
    def handle_request(_request, _state) do
      response(:ok)
      |> set_body("Hello, World!")
    end
  end

  setup do
    stack =
      Raxx.Stack.new(
        [{Raxx.BasicAuthentication, %{user_id: "Aladdin", password: "open sesame"}}],
        {SimpleApp, nil}
      )

    {:ok, stack: stack}
  end

  test "Request with valid authentication passes through stack", %{stack: stack} do
    request =
      request(:GET, "/")
      |> set_header("authorization", "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")

    assert {[response], _} = Server.handle_head(stack, request)
    assert response.status == 200
    assert response.body == "Hello, World!"
  end

  test "Request with no authentication is denied", %{stack: stack} do
    request = request(:GET, "/")

    # TODO, what is the state of helpers here, can the middleware just return a response?
    # assert {[response], _} = Server.handle_head(stack, request)
    # assert response.status == 401
  end

  test "Request with invalid credentials is denied", %{stack: stack} do
    request =
      request(:GET, "/")
      |> set_basic_authentication("Jafar", "Genie")

    # TODO, what is the state of helpers here, can the middleware just return a response?
    # assert {[response], _} = Server.handle_head(stack, request)
    # assert response.status == 401
  end
end
