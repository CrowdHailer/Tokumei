defmodule Raxx.BasicAuthentication do
  @moduledoc """
  Helpers for working with Basic authentication in Raxx applications.

  *Tests import functions from `Raxx`, e.g. `get_header`.*
  """
  alias Raxx.Request

  @authentication_header "authorization"

  use Raxx.Middleware

  @impl Raxx.Middleware
  def process_head(request, config, next) do
    case fetch_basic_authentication(request) do
      {:ok, {user_id, password}} ->
        if secure_compare(user_id, config.user_id) && secure_compare(password, config.password) do
          {parts, next} = Raxx.Server.handle_head(next, request)
          {parts, config, next}
        else
          {Raxx.separate_parts([unauthorized()]), config, next}
        end

      _ ->
        {Raxx.separate_parts([unauthorized()]), config, next}
    end
  end

  @doc """
  Add a clients credentials to a request to authenticate it,
  using the 'Basic' HTTP authentication scheme.

  This function will raise an exception if either user_id or password is invalid,
  see `BasicAuthentication.encode_authorization` for details.

  ## Examples

      iex> request(:GET, "/")
      ...> |> set_basic_authentication("Aladdin", "open sesame")
      ...> |> get_header("authorization")
      "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ=="
  """
  def set_basic_authentication(request = %Request{}, user_id, password) do
    {:ok, authentication_header} = BasicAuthentication.encode_authentication(user_id, password)
    # Raise on bad credentials
    request
    |> Raxx.set_header(@authentication_header, authentication_header)
  end

  @doc """
  Extract a clients credentials submitted using the 'Basic' HTTP authentication scheme.

  If authentication of request is not set of invalid an error is returned.

  ## Examples
      iex> request(:GET, "/")
      ...> |> set_header("authorization", "Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
      ...> |> fetch_basic_authentication()
      {:ok, {"Aladdin", "open sesame"}}

      iex> request(:GET, "/")
      ...> |> fetch_basic_authentication()
      {:error, :no_authorization_header}
  """
  def fetch_basic_authentication(request = %Request{}) do
    case Raxx.get_header(request, @authentication_header) do
      nil ->
        {:error, :no_authorization_header}

      authentication_header ->
        BasicAuthentication.decode_authentication(authentication_header)
    end
  end

  @default_realm "Site"
  @default_charset "UTF-8"

  @doc """
  Generate a response to a request that failed to authenticate.

  The response will contain a challenge for the client in the `www-authenticate` header.
  Use an unauthorized response to prompt a client into providing basic authentication credentials.

  ## Options

  - **realm:** describe the protected area. default `"Site"`
  - **charset:** default `"UTF-8"`

  ### Notes

  - The only valid charset is `UTF-8`; https://tools.ietf.org/html/rfc7617#section-2.1.
    A `nil` can be provided to this function to omit the parameter.

  - Validation should be added for the parameter values to ensure they only accept valid values.
  """
  def unauthorized(options \\ []) do
    realm = Keyword.get(options, :realm, @default_realm)
    charset = Keyword.get(options, :charset, @default_charset)

    Raxx.response(:unauthorized)
    |> Raxx.set_header("www-authenticate", BasicAuthentication.encode_challenge(realm, charset))
    |> Raxx.set_body("401 Unauthorized")
  end

  # This is only used because we have the dumb middleware version
  @doc """
  Compares the two binaries in constant-time to avoid timing attacks.
  See: http://codahale.com/a-lesson-in-timing-attacks/
  """
  def secure_compare(left, right) do
    if byte_size(left) == byte_size(right) do
      secure_compare(left, right, 0) == 0
    else
      false
    end
  end

  defp secure_compare(<<x, left::binary>>, <<y, right::binary>>, acc) do
    import Bitwise
    xorred = x ^^^ y
    secure_compare(left, right, acc ||| xorred)
  end

  defp secure_compare(<<>>, <<>>, acc) do
    acc
  end
end
