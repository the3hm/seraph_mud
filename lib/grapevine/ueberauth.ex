defmodule Grapevine.Ueberauth.Strategy do
  @moduledoc """
  Grapevine authentication strategy for Ueberauth
  """

  use Ueberauth.Strategy, default_scope: "profile email"

  alias Grapevine.Ueberauth.Strategy.OAuth

  # Module-level configuration
  @client_id Application.compile_env(:gossip, :client_id, nil)
  @client_secret Application.compile_env(:gossip, :client_secret, nil)
  @site "https://grapevine.haus"
  @authorize_url "/oauth/authorize"
  @token_url "/oauth/token"

  defmodule OAuth do
    @moduledoc """
    OAuth client used by the Grapevine Ueberauth strategy
    """

    use OAuth2.Strategy

    def client(opts \\ []) do
      # Use compile-time configuration safely
      opts =
        [
          strategy: __MODULE__,
          site: @site,
          authorize_url: @authorize_url,
          token_url: @token_url
        ]
        |> Keyword.merge(opts)
        |> Keyword.merge(client_id: @client_id, client_secret: @client_secret)
        |> Enum.reject(fn {_k, v} -> is_nil(v) end)

      OAuth2.Client.new(opts)
    end

    def authorize_url!(params \\ [], opts \\ []) do
      opts
      |> client()
      |> OAuth2.Client.authorize_url!(params)
    end

    def get(token, url, opts \\ []) do
      [token: token]
      |> Keyword.merge(opts)
      |> client()
      |> OAuth2.Client.get(url)
    end

    def get_access_token(params \\ [], opts \\ []) do
      case opts |> client() |> OAuth2.Client.get_token(params) do
        {:error, %{body: %{"error" => error, "error_description" => description}}} ->
          {:error, {error, description}}

        {:ok, %{token: %{access_token: nil} = token}} ->
          %{"error" => error, "error_description" => description} = token.other_params
          {:error, {error, description}}

        {:ok, %{token: token}} ->
          {:ok, token}
      end
    end

    def authorize_url(client, params) do
      OAuth2.Strategy.AuthCode.authorize_url(client, params)
    end

    def get_token(client, params, headers) do
      client
      |> put_header("Accept", "application/json")
      |> put_header("Content-Type", "application/json")
      |> OAuth2.Strategy.AuthCode.get_token(params, headers)
    end
  end

  @impl true
  def handle_request!(conn) do
    scopes = Keyword.get(options(conn), :scope, Keyword.get(default_options(), :default_scope))

    params = [scope: scopes, state: UUID.uuid4()]
    opts = [site: site(conn), redirect_uri: callback_url(conn)]

    redirect!(conn, OAuth.authorize_url!(params, opts))
  end

  @impl true
  def handle_callback!(%Plug.Conn{params: %{"code" => code}} = conn) do
    params = [code: code]
    opts = [site: site(conn), redirect_uri: callback_url(conn)]

    case OAuth.get_access_token(params, opts) do
      {:ok, token} ->
        fetch_user(conn, token)

      {:error, {error_code, error_description}} ->
        set_errors!(conn, [error(error_code, error_description)])
    end
  end

  def handle_callback!(%Plug.Conn{params: %{"error" => "access_denied"}} = conn) do
    set_errors!(conn, [error("OAuth2", "Access was denied")])
  end

  def handle_callback!(conn) do
    set_errors!(conn, [error("OAuth2", "Failure to authenticate")])
  end

  @impl true
  def credentials(conn) do
    token = conn.private.grapevine_token

    %Ueberauth.Auth.Credentials{
      expires: true,
      expires_at: token.expires_at,
      refresh_token: token.refresh_token,
      token: token.access_token
    }
  end

  @impl true
  def uid(conn), do: conn.private.grapevine_user["uid"]

  @impl true
  def info(conn) do
    %Ueberauth.Auth.Info{
      email: conn.private.grapevine_user["email"],
      name: conn.private.grapevine_user["username"]
    }
  end

  defp fetch_user(conn, token) do
    conn = put_private(conn, :grapevine_token, token)
    opts = [site: site(conn)]

    case OAuth.get(token, "/users/me", opts) do
      {:ok, %OAuth2.Response{status_code: 401}} ->
        set_errors!(conn, [error("token", "unauthorized")])

      {:ok, %OAuth2.Response{status_code: 200, body: user}} ->
        put_private(conn, :grapevine_user, user)

      {:error, %OAuth2.Response{status_code: code}} ->
        set_errors!(conn, [error("OAuth2", code)])

      {:error, %OAuth2.Error{reason: reason}} ->
        set_errors!(conn, [error("OAuth2", reason)])
    end
  end

  defp site(conn), do: Keyword.get(options(conn), :site)
end
