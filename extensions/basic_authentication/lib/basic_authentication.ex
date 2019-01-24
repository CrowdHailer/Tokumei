defmodule BasicAuthentication do
  @moduledoc """
  Submit and verify client credentials using Basic authentication.

  *The 'Basic' authentication scheme is specified in RFC 7617 (which obsoletes RFC 2617).
  This scheme is not a secure method of user authentication,
  see https://tools.ietf.org/html/rfc7617#section-4*

  The HTTP header `authorization` is actually used for authentication.
  Function names in this project use the term authentication where possible.
  """

  @doc """
  Encode client credentials to an authorization header value

  NOTE:
  1. The user-id and password MUST NOT contain any control characters
  2. The user-id must not contain a `:`
   -> {ok, headerstring}
  """
  def encode_authentication(user_id, password) do
    case user_pass(user_id, password) do
      {:ok, pass} ->
        {:ok, "Basic " <> Base.encode64(pass)}
    end
  end

  @doc """
  Decode an authorization header to client credentials.

  ## Examples

      iex> decode_authentication("Basic QWxhZGRpbjpvcGVuIHNlc2FtZQ==")
      {:ok, {"Aladdin", "open sesame"}}

      iex> decode_authentication("Basic !!BAD")
      {:error, :unable_to_decode_user_pass}

      iex> decode_authentication("Bearer my-token")
      {:error, :unknown_authentication_method}
  """
  def decode_authentication(authentication_header) do
    case String.split(authentication_header, " ", parts: 2) do
      ["Basic", encoded] ->
        case Base.decode64(encoded) do
          {:ok, user_pass} ->
            case String.split(user_pass, ":", parts: 2) do
              [user_id, password] ->
                {:ok, {user_id, password}}

              _ ->
                {:error, :invalid_user_pass}
            end

          :error ->
            {:error, :unable_to_decode_user_pass}
        end

      [_unknown, _] ->
        {:error, :unknown_authentication_method}

      _ ->
        {:error, :invalid_authentication_header}
    end
  end

  def encode_challenge(realm, nil) do
    "Basic realm=\"#{realm}\""
  end

  def encode_challenge(realm, charset) do
    "Basic realm=\"#{realm}\", charset=\"#{charset}\""
  end

  # A decode challenge might be useful here, but i've never used it

  # expose valid user_id valid_password functions
  # what to do if extracting data returns invalid user_id or password
  # nothing and yet people use the check functions
  # use check function in middleware
  defp user_pass(user_id, password) do
    case :binary.match(user_id, [":"]) do
      {_, _} ->
        raise "a user-id containing a colon character is invalid"

      :nomatch ->
        {:ok, user_id <> ":" <> password}
    end
  end
end
