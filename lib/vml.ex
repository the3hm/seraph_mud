defmodule VML do
  @moduledoc """
  Parse VML text strings
  """

  require Logger

  @doc """
  Parse, raise on errors
  """
  def parse!(string) do
    case parse(string) do
      {:ok, ast} ->
        ast

      {:error, _type, error} ->
        raise error
    end
  end

  @doc """
  Parse a string into an AST for processing
  """
  def parse(list) when is_list(list), do: {:ok, list}

  def parse(string) do
    case :vml_lexer.string(String.to_charlist(string)) do
      {:ok, tokens, _} ->
        parse_tokens(tokens)

      {:error, {_, _, reason}} ->
        Logger.warning("Encountered a lexing error for #{inspect(string)} - #{inspect(reason)}")
        {:error, :lexer, reason}
    end
  end

  def escape(string) do
    string
    |> String.replace("[", "\\[")
    |> String.replace("]", "\\]")
    |> String.replace("{", "\\{")
    |> String.replace("}", "\\}")
  end

  @doc """
  Convert a processed (no variables) AST back to a string
  """
  def collapse(string) when is_binary(string), do: string

  def collapse(integer) when is_integer(integer), do: to_string(integer)

  def collapse(float) when is_float(float), do: to_string(float)

  def collapse(atom) when is_atom(atom), do: to_string(atom)

  def collapse({:variable, variable}) do
    "[#{variable}]"
  end

  def collapse({:tag, attributes, nodes}) do
    name = Keyword.get(attributes, :name)

    case Keyword.get(attributes, :attributes) do
      nil ->
        "{#{name}}#{collapse(nodes)}{/#{name}}"

      [] ->
        "{#{name}}#{collapse(nodes)}{/#{name}}"

      attributes ->
        "{#{name} #{collapse_attributes(attributes)}}#{collapse(nodes)}{/#{name}}"
    end
  end

  def collapse({:string, string}), do: string

  def collapse(list) when is_list(list) do
    list
    |> Enum.map(&collapse/1)
    |> Enum.join()
  end

  defp collapse_attributes(attributes) do
    attributes
    |> Enum.map(fn {key, value} ->
      value = Enum.map(value, &collapse/1)
      "#{key}='#{value}'"
    end)
    |> Enum.join(" ")
  end

  @doc false
  def parse_tokens(tokens) do
    case :vml_parser.parse(tokens) do
      {:ok, ast} ->
        {:ok, pre_process(ast)}

      {:error, {_, _, reason}} ->
        Logger.warning("Encountered a parsing error for #{inspect(tokens)} - #{inspect(reason)}")
        {:error, :parser, reason}
    end
  end

  @doc """
  Preprocess the AST

  - Turn charlists into elixir strings
  - Collapse blocks of string nodes
  """
  def pre_process(ast) do
    ast
    |> Enum.map(&process_node/1)
    |> collapse_strings()
  end

  @doc """
  Process a single node

  Handles strings, variables, resources, and tags. Everything else
  passes through without change.
  """
  def process_node({:string, string}) do
    {:string, to_string(string)}
  end

  def process_node({:variable, string}) do
    {:variable, to_string(string)}
  end

  def process_node({:variable, {:space, space}, {:name, string}}) do
    {:variable, {:space, to_string(space)}, {:name, to_string(string)}}
  end

  def process_node({:variable, {:name, string}, {:space, space}}) do
    {:variable, {:name, to_string(string)}, {:space, to_string(space)}}
  end

  def process_node({:resource, resource, id}) do
    {:resource, to_string(resource), to_string(id)}
  end

  def process_node({:tag, attributes, nodes}) do
    attributes =
      Enum.map(attributes, fn {key, value} ->
        {key, process_attribute(key, value)}
      end)

    {:tag, attributes, pre_process(nodes)}
  end

  def process_node(node), do: node

  defp process_attribute(:name, value) do
    value
    |> Enum.map(fn {:string, value} ->
      to_string(value)
    end)
    |> Enum.join()
  end

  defp process_attribute(:attributes, attributes) do
    Enum.map(attributes, fn attribute ->
      process_attribute(:attribute, attribute)
    end)
  end

  defp process_attribute(:attribute, {name, values}) do
    values = Enum.map(values, &process_node/1)
    {to_string(name), collapse_strings(values)}
  end

  @doc """
  Collapse string nodes next to each other into a single node

  Recurses through the list adding the newly collapsed node into the processing stream.

      iex> VML.collapse_strings([string: "hello", string: " ", string: "world"])
      [string: "hello world"]

      iex> VML.collapse_strings([variable: "name", string: ",", string: " ", string: "hello", string: " ", string: "world"])
      [variable: "name", string: ", hello world"]
  """
  def collapse_strings([]), do: []

  def collapse_strings([{:string, string1}, {:string, string2} | nodes]) do
    collapse_strings([{:string, to_string(string1) <> to_string(string2)} | nodes])
  end

  def collapse_strings([node | nodes]) do
    [node | collapse_strings(nodes)]
  end
end
