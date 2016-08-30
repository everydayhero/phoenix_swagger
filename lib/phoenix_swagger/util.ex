defmodule PhoenixSwagger.Util do
  @moduledoc "Helper functions and macros for implementing swagger DSL"

  @doc """
  Given a do-end `block`, insert the pipline operator |> between each expression,
  turning the whole thing into a single expression.
  """
  def pipeline_body(block)
  def pipeline_body([do: {:__block__, _, [head | tail]}]) do
    Enum.reduce(tail, head, fn next, pipeline ->
      quote do unquote(pipeline) |> unquote(next) end
    end)
  end
  def pipeline_body([do: expr]) do expr end


  @doc """
  Converts `value` to a json-encodable form, removes nils from structs and maps.
  """
  def to_json(value = %{__struct__: _}) do
    value
    |> Map.from_struct
    |> to_json
  end
  def to_json(value) when is_map(value) do
    value
    |> Enum.map(fn {k,v} -> {to_string(k), to_json(v)} end)
    |> Enum.filter(fn {_, :null} -> false; _ -> true end)
    |> Enum.into(%{})
  end
  def to_json(value) when is_list(value) do
    Enum.map(value, &to_json/1)
  end
  def to_json(nil) do :null end
  def to_json(:null) do :null end
  def to_json(true) do true end
  def to_json(false) do false end
  def to_json(value) when is_atom(value) do to_string(value) end
  def to_json(value) do value end
end
