defmodule Web.AuthenticatedController do
  @moduledoc """
  Shared controller logic for any authenticated routes.

  Injects a `load_user/2` plug that assigns the user based on the `:user_token` in the session.
  """

  defmacro __using__(_opts) do
    quote do
      use Web, :controller

      alias Web.Router.Helpers, as: Routes

      plug :load_user

      @doc false
      defp load_user(conn, _opts) do
        case get_session(conn, :user_token) do
          nil -> conn
          token -> _load_user(conn, Web.User.from_token(token))
        end
      end

      @doc false
      defp _load_user(conn, nil), do: conn

      defp _load_user(conn, user) do
        assign(conn, :user, user)
      end
    end
  end
end
