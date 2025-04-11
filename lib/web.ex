defmodule Web do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels, and so on.

  This can be used in your application as:

      use Web, :controller
      use Web, :view

  The definitions below will be executed for every view,
  controller, etc., so keep them short and clean, focused
  on imports, uses, and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  # ✅ Needed for verified routes (~p sigil)
  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  # This helper is used for VerifiedRoutes with the ~p sigil
  defp verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: Web.Endpoint,
        router: Web.Router,
        statics: Web.static_paths()  # This uses static paths defined above
    end
  end

  # Controller-specific behavior
  def controller do
    quote do
      use Phoenix.Controller,
        namespace: Web,
        formats: [:html, :json],
        layouts: [html: Web.Layouts]

      import Plug.Conn
      import Phoenix.VerifiedRoutes

      # Importing Web.Router.Helpers directly here
      alias Web.Router.Helpers, as: Routes

      unquote(verified_routes())  # Inject verified routes for use in controllers
    end
  end

  # View-specific behavior
  def view do
    quote do
      use Phoenix.View,
        root: "lib/web/templates",
        namespace: Web

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 2, view_module: 1]

      # Use all HTML functionality (forms, tags, etc)
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      alias Web.Router.Helpers, as: Routes  # Alias for easier access to routes
      import Web.ErrorHelpers
      use Gettext, backend: Web.Gettext

      alias Web.FormView
      alias Web.Views.Help
      alias Web.ReactView, as: React
      alias Web.Router.Helper, as: RouterHelper
    end
  end

  # Router-specific behavior
  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  # Channel-specific behavior
  def channel do
    quote do
      use Phoenix.Channel
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])  # Dispatch to the right method (controller, view, etc)
  end
end
