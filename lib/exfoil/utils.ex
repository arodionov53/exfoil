defmodule Exfoil.Utils do
  @moduledoc """
  Utility functions shared across Exfoil modules.
  """

  @doc """
  Normalizes a module name to PascalCase format.

  ## Examples

      iex> Exfoil.Utils.normalize_module_name(:person)
      :Person

      iex> Exfoil.Utils.normalize_module_name(:user_profile)
      :UserProfile

      iex> Exfoil.Utils.normalize_module_name(:UserData)
      :UserData
  """
  def normalize_module_name(module_name) do
    str = to_string(module_name)

    # If it's already in PascalCase (starts with uppercase), keep it as is
    if String.match?(str, ~r/^[A-Z]/) do
      String.to_atom(str)
    else
      # Otherwise, split on underscores and capitalize each part
      str
      |> String.split("_")
      |> Enum.map(&String.capitalize/1)
      |> Enum.join("")
      |> String.to_atom()
    end
  end

  @doc """
  Normalizes a function name to valid Elixir format (lowercase).

  Function names must start with a lowercase letter or underscore.

  ## Examples

      iex> Exfoil.Utils.normalize_function_name(:Lookup)
      :lookup

      iex> Exfoil.Utils.normalize_function_name(:GetData)
      :getdata

      iex> Exfoil.Utils.normalize_function_name(:_PrivateGet)
      :_privateget

      iex> Exfoil.Utils.normalize_function_name(:fetch)
      :fetch
  """
  def normalize_function_name(function_name) do
    str = to_string(function_name)

    # Function names must start with lowercase letter or underscore
    cond do
      # If it starts with underscore followed by uppercase, preserve underscore but lowercase the rest
      String.match?(str, ~r/^_[A-Z]/) ->
        "_" <> rest = str
        String.to_atom("_" <> String.downcase(rest))

      # If it starts with uppercase, convert to lowercase
      String.match?(str, ~r/^[A-Z]/) ->
        str
        |> String.downcase()
        |> String.to_atom()

      # Otherwise keep as is
      true ->
        String.to_atom(str)
    end
  end
end