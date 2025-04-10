defmodule Web.MailController do
  @moduledoc """
  Handles in-game mail: viewing inbox, sending messages, and reading mail.
  """

  use Web, :controller

  alias Web.Mail
  alias Web.Router.Helpers, as: Routes

  plug Web.Plug.PublicEnsureUser
  plug Web.Plug.PublicEnsureCharacter
  plug Web.Plug.FetchPage when action in [:index]

  plug :load_mail when action in [:show]
  plug :ensure_your_mail! when action in [:show]

  @doc """
  Displays paginated mail inbox for the current character.
  """
  def index(conn, _params) do
    %{current_character: character, page: page, per: per} = conn.assigns
    %{page: mail, pagination: pagination} = Mail.all(character, page: page, per: per)

    render(conn, "index.html",
      mail_pieces: mail,
      pagination: pagination
    )
  end

  @doc """
  Shows a single piece of mail.
  """
  def show(%{assigns: %{mail: mail}} = conn, _params) do
    Mail.mark_read!(mail)
    render(conn, "show.html")
  end

  @doc """
  Renders the new mail form.
  """
  def new(conn, _params) do
    render(conn, "new.html", changeset: Mail.new())
  end

  @doc """
  Sends a mail message from the current character.
  """
  def create(%{assigns: %{current_character: sender}} = conn, %{"mail" => params}) do
    case Mail.send(sender, params) do
      {:ok, _mail} ->
        conn
        |> put_flash(:info, "Mail sent!")
        |> redirect(to: Routes.public_mail_path(conn, :index))

      {:error, changeset} ->
        render(conn, "new.html", changeset: changeset)

      {:error, :receiver, :not_found} ->
        conn
        |> put_flash(:error, "Receiver could not be found.")
        |> redirect(to: Routes.public_mail_path(conn, :index))
    end
  end

  defp load_mail(conn, _opts) do
    case conn.params do
      %{"id" => id} ->
        case Mail.get(id) do
          nil ->
            conn
            |> redirect(to: Routes.public_mail_path(conn, :index))
            |> halt()

          mail ->
            assign(conn, :mail, mail)
        end

      _ ->
        conn
        |> redirect(to: Routes.public_mail_path(conn, :index))
        |> halt()
    end
  end

  defp ensure_your_mail!(%{assigns: %{current_user: user, mail: mail}} = conn, _opts) do
    if user.id == mail.receiver_id do
      conn
    else
      conn
      |> redirect(to: Routes.public_mail_path(conn, :index))
      |> halt()
    end
  end
end
