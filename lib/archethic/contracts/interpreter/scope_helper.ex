defmodule Archethic.Contracts.Interpreter.ScopeHelper do
  @moduledoc """
  Helper functions to deal with scopes
  """
  @doc """
  Adds a new reference to the first "context" list of our scope acc.
  "Contexts" are used to separate a custom function's scope from the scope of the rest of the code.
  """
  def add_ref(acc) do
    ref = :erlang.list_to_binary(:erlang.ref_to_list(make_ref()))
    [first | rest] = acc
    first = first ++ [ref]
    [first | rest]
  end

  @doc """
  Removes the last reference from the first "context" list of our scope acc.
  """
  def remove_ref(acc) do
    [first | rest] = acc
    modified_first = List.delete_at(first, -1)
    [modified_first | rest]
  end
end
