defmodule Web.ErrorHelpers do
  @moduledoc """
  Conveniences for translating and building error messages.
  """

  import Phoenix.HTML
  import Phoenix.HTML.Form
  use PhoenixHTMLHelpers

  @doc """
  Generates tag for inlined form input errors.
  """
  def error_tag(form, field) do
    Enum.map(Keyword.get_values(form.errors, field), fn error ->
      content_tag(:span, translate_error(error), class: "help-block text-danger")
    end)
  end

  @doc """
  Translates an error message using Gettext.

  This version safely handles dynamic messages at runtime.
  """
  def translate_error({msg, opts}) do
    if count = opts[:count] do
      Gettext.dngettext(Web.Gettext, "errors", msg, msg, count, opts)
    else
      Gettext.dgettext(Web.Gettext, "errors", msg, opts)
    end
  end
end
