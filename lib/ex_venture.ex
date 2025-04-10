defmodule ExVenture do
  @moduledoc false

  @doc """
  Helper function for loading system environment variables in configuration.
  Supports three formats:
    - `{:system, "ENV_NAME"}`
    - `{:system, "ENV_NAME", default}`
    - literal values (passed through)
  """
  @spec config({:system, String.t()} | {:system, String.t(), any()} | any()) :: any()
  def config({:system, name}), do: System.get_env(name)
  def config({:system, name, default}), do: System.get_env(name) || default
  def config(value), do: value

  @doc """
  Cast a configuration value into an integer.
  Works for integer literals or string ENV values.
  """
  @spec config_integer(any()) :: integer()
  def config_integer(value) do
    case config(value) do
      int when is_integer(int) -> int
      str when is_binary(str) -> String.to_integer(str)
    end
  end

  @doc """
  Return the version of ExVenture loaded at runtime.
  Example: "ExVenture v0.1.0"
  """
  @spec version() :: String.t()
  def version do
    case :application.get_key(:ex_venture, :vsn) do
      {:ok, vsn} -> "ExVenture v#{vsn}"
      _ -> "ExVenture vUnknown"
    end
  end

  @doc """
  Return the Git SHA or version identifier compiled into the app.
  Looks up the value from compile-time configuration.
  """
  @sha_version Application.compile_env(:ex_venture, :version, "unknown")
  @spec sha_version() :: String.t()
  def sha_version, do: @sha_version
end
