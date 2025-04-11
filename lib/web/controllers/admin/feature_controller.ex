defmodule Web.Admin.FeatureController do
  @moduledoc """
  Admin controller for managing room features.

  Allows administrators to list, create, edit, view, and delete persistent features
  that can be applied to rooms or zones.
  """

  use Web.AdminController

  alias Web.Feature

  plug(Web.Plug.FetchPage when action in [:index])

  @doc """
  Lists all features with optional filtering.
  """
  def index(conn, params) do
    %{page: page, per: per} = conn.assigns
    filter = Map.get(params, "feature", %{})
    %{page: features, pagination: pagination} = Feature.all(filter: filter, page: page, per: per)

    render(conn, :index,
      features: features,
      filter: filter,
      pagination: pagination
    )
  end

  @doc """
  Shows a single feature.
  """
  def show(conn, %{"id" => id}) do
    feature = Feature.get(id)
    render(conn, :show, feature: feature)
  end

  @doc """
  Renders a new feature form.
  """
  def new(conn, _params) do
    render(conn, :new, changeset: Feature.new())
  end

  @doc """
  Creates a new feature.
  """
  def create(conn, %{"feature" => params}) do
    case Feature.create(params) do
      {:ok, feature} ->
        redirect(conn,
          to: ~p"/admin/features/#{feature.id}",
          flash: [info: "#{feature.key} created!"]
        )

      {:error, changeset} ->
        render(conn, :new,
          changeset: changeset,
          error_flash: "There was a problem creating the feature. Please try again."
        )
    end
  end

  @doc """
  Renders the form to edit an existing feature.
  """
  def edit(conn, %{"id" => id}) do
    feature = Feature.get(id)
    render(conn, :edit, feature: feature, changeset: Feature.edit(feature))
  end

  @doc """
  Updates a feature.
  """
  def update(conn, %{"id" => id, "feature" => params}) do
    case Feature.update(id, params) do
      {:ok, feature} ->
        redirect(conn,
          to: ~p"/admin/features/#{feature.id}",
          flash: [info: "#{feature.key} updated!"]
        )

      {:error, changeset} ->
        feature = Feature.get(id)

        render(conn, :edit,
          feature: feature,
          changeset: changeset,
          error_flash: "There was a problem updating #{feature.key}. Please try again."
        )
    end
  end

  @doc """
  Deletes a feature.
  """
  def delete(conn, %{"id" => id}) do
    case Feature.delete(id) do
      {:ok, feature} ->
        redirect(conn,
          to: ~p"/admin/features",
          flash: [info: "#{feature.key} has been deleted!"]
        )

      {:error, _changeset} ->
        redirect(conn,
          to: ~p"/admin/features",
          flash: [error: "There was an issue deleting the feature. Please try again."]
        )
    end
  end
end
