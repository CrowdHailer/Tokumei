defmodule Raxx.BasicAuthentication do
  @moduledoc """
  Helpers for working with Basic authentication in Raxx applications.

  *Tests import functions from `Raxx`, e.g. `get_header`.*
  """
  alias Raxx.Request

  @authentication_header "authorization"

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
  def unauthorized(options) do
    realm = Keyword.get(options, :realm, @default_realm)
    charset = Keyword.get(options, :charset, @default_charset)

    Raxx.response(:unauthorized)
    |> Raxx.set_header("www-authenticate", BasicAuthentication.encode_challenge(realm, charset))
    |> Raxx.set_body("401 Unauthorized")
  end
end
