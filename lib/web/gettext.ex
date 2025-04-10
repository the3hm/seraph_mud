defmodule Web.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """

  # NEW: Use the proper backend declaration (as of Gettext 0.24+)
  use Gettext.Backend, otp_app: :ex_venture
end
