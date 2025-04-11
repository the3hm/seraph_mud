defmodule Web.Admin.NoteController do
  @moduledoc """
  Admin controller for managing Notes.
  Supports listing, viewing, creating, editing, and updating notes.
  """

  use Web.AdminController

  alias Web.Note
  alias Web.Router.Helpers, as: Routes

  plug(Web.Plug.FetchPage when action in [:index])

  @doc """
  List all notes with optional filters.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "note", %{})
    %{page: notes, pagination: pagination} = Note.all(filter: filter, page: page, per: per)

    render(conn, "index.html",
      notes: notes,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Show a single note.
  """
  def show(conn, %{"id" => id}) do
    note = Note.get(id)

    render(conn, "show.html", note: note)
  end

  @doc """
  Render the form to create a new note.
  """
  def new(conn, _params) do
    changeset = Note.new()

    render(conn, "new.html", changeset: changeset)
  end

  @doc """
  Handle creation of a new note.
  """
  def create(conn, %{"note" => params}) do
    case Note.create(params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, "#{note.name} created!")
        |> redirect(to: Routes.note_path(conn, :show, note.id))

      {:error, changeset} ->
        conn
        |> put_flash(:error, "There was an issue creating the note. Please try again.")
        |> render("new.html", changeset: changeset)
    end
  end

  @doc """
  Render the form to edit an existing note.
  """
  def edit(conn, %{"id" => id}) do
    note = Note.get(id)
    changeset = Note.edit(note)

    render(conn, "edit.html",
      note: note,
      changeset: changeset
    )
  end

  @doc """
  Update an existing note.
  """
  def update(conn, %{"id" => id, "note" => params}) do
    case Note.update(id, params) do
      {:ok, note} ->
        conn
        |> put_flash(:info, "#{note.name} updated!")
        |> redirect(to: Routes.note_path(conn, :show, note.id))

      {:error, changeset} ->
        note = Note.get(id)

        conn
        |> put_flash(:error, "There was an issue updating #{note.name}. Please try again.")
        |> render("edit.html",
          note: note,
          changeset: changeset
        )
    end
  end
end
