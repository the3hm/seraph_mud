defmodule Game.Format.Template do
  @moduledoc """
  Template a string with variables
  """

  @doc """
  Render a template with a context

  Variables are denoted with `[key]` in the template string. You can also
  include leading spaces that can be collapsed if the variable is nil or does
  not exist in the context.

  For instance:

      ~s(You say[ adverb_phrase], {say}"[message]"{/say})

  If templated with `%{message: "Hello"}` will output as:

      You say, {say}"Hello"{/say}
  """
  @spec render(String.t(), map()) :: String.t()
  def render(context, string) do
    context =
      context
      |> render_many()
      |> Map.get(:assigns, %{})
      |> Enum.into(%{}, fn {key, val} -> {to_string(key), val} end)

    with {:ok, ast} <- VML.parse(string) do
      VML.collapse(replace_variables(ast, context))
    else
      {:error, _module, _error} ->
        "{error}Could not parse text.{/error}"
    end
  end

  defp render_many(context) do
    assigns =
      Enum.reduce(context.many_assigns, context.assigns, fn {key, {values, fun, opts}}, assigns ->
        values =
          values
          |> Enum.map(fun)
          |> Enum.join(Keyword.get(opts, :joiner, "\n"))

        Map.put(assigns, key, values)
      end)

    Map.put(context, :assigns, assigns)
  end

  defp replace_variables([], _context), do: []

  defp replace_variables([node | nodes], context) do
    [replace_variable(node, context) | replace_variables(nodes, context)]
  end

  defp replace_variable({:variable, {:space, space}, {:name, name}}, context) do
    case replace_variable({:variable, name}, context) do
      {:string, ""} ->
        {:string, ""}

      {:string, value} ->
        {:string, to_string(space) <> value}

      value when is_list(value) ->
        [{:string, space} | value]
    end
  end

  defp replace_variable({:variable, {:name, name}, {:space, space}}, context) do
    case replace_variable({:variable, name}, context) do
      {:string, ""} ->
        {:string, ""}

      {:string, value} ->
        {:string, to_string(value) <> space}

      value when is_list(value) ->
        value ++ [{:string, space}]
    end
  end

  defp replace_variable({:variable, name}, context) do
    case Map.get(context, name, "") do
      "" ->
        {:string, ""}

      nil ->
        {:string, ""}

      value when is_list(value) ->
        value

      value ->
        {:string, to_string(value)}
    end
  end

  defp replace_variable({:tag, attributes, nodes}, context) do
    name = Keyword.get(attributes, :name)
    attributes = Keyword.get(attributes, :attributes, [])

    attributes =
      attributes
      |> Enum.map(fn {key, value} ->
        {key, replace_variables(value, context)}
      end)

    {:tag, [name: name, attributes: attributes], replace_variables(nodes, context)}
  end

  defp replace_variable(node, _context), do: node
end
