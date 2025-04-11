defmodule Web.Admin.ColorCodeController do
  @moduledoc """
  Admin controller for managing individual color codes used in the game UI.
  """

  use Web.AdminController

  alias Web.ColorCode

  @doc """
  Renders the form to create a new color code.
  """
  def new(conn, _params) do
    render(conn, :new, changeset: ColorCode.new())
  end

  @doc """
  Handles creation of a new color code.
  """
  def create(conn, %{"color_code" => params}) do
    case ColorCode.create(params) do
      {:ok, color_code} ->
        redirect(conn,
          to: ~p"/admin/colors",
          flash: [info: "#{color_code.key} created!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          error_flash: "There was an issue creating the color code. Please try again."
        )
    end
  end

  @doc """
  Renders the edit form for an existing color code.
  """
  def edit(conn, %{"id" => id}) do
    color_code = ColorCode.get(id)

    render(conn, :edit,
      color_code: color_code,
      changeset: ColorCode.edit(color_code)
    )
  end

  @doc """
  Updates an existing color code with new values.
  """
  def update(conn, %{"id" => id, "color_code" => params}) do
    case ColorCode.update(id, params) do
      {:ok, color_code} ->
        redirect(conn,
          to: ~p"/admin/colors",
          flash: [info: "#{color_code.key} updated!"]
        )

      {:error, changeset} ->
        color_code = ColorCode.get(id)

        render(conn, :edit,
          color_code: color_code,
          changeset: changeset,
          error_flash: "There was a problem updating #{color_code.key}. Please try again."
        )
    end
  end
end
