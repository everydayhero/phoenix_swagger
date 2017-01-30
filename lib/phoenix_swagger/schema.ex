defmodule PhoenixSwagger.Schema do
  @moduledoc """
  Struct and helpers for swagger schema
  """

  alias PhoenixSwagger.Schema

  defstruct(
    '$ref': nil,
    format: nil,
    title: nil,
    description: nil,
    default: nil,
    multipleOf: nil,
    maximum: nil,
    exclusiveMaximum: nil,
    minimum: nil,
    exclusiveMinimum: nil,
    maxLength: nil,
    minLength: nil,
    pattern: nil,
    maxItems: nil,
    minItems: nil,
    uniqueItems: nil,
    enum: nil,
    maxProperties: nil,
    minProperties: nil,
    required: nil,
    enum: nil,
    type: nil,
    items: nil,
    allOf: nil,
    properties: nil,
    additionalProperties: nil)

  @doc """
  Construct a schema reference, using name of definition in this swagger document,
    or a complete path.
  """
  def ref(name) when is_atom(name) do
    %Schema{'$ref': "#/definitions/#{name}"}
  end
  def ref(path) when is_binary(path) do
    %Schema{'$ref': path}
  end

  @doc """
  Construct an array schema, where the array items schema is a ref to the given name.

  Schema.array(:User) == %Schema{type: :array, items: Schema.ref(:User)}
  """
  def array(name) when is_atom(name) do
    %Schema{
      type: :array,
      items: ref(name)
    }
  end

  @doc """
  Sets the description for the schema
  """
  def description(model = %Schema{}, desc) do
    %{model | description: desc}
  end

  @doc """
  Sets a property of the Schema
  """
  def property(model, name, type, description, opts \\ [])
  def property(model = %Schema{}, name, type, description, opts) when is_atom(type) do
    property(model, name, %Schema{type: type}, description, opts)
  end
  def property(model = %Schema{}, name, type = %Schema{}, description, opts) do
    required = case {model.required, opts[:required]} do
      {nil, true} -> [name]
      {r, true} -> r ++ [name]
      {r, _} -> r
    end

    property_schema = struct!(type, Keyword.delete(opts, :required) ++ [description: description])
    properties = (model.properties || %{}) |> Map.put(name, property_schema)

    %{model | properties: properties, required: required}
  end
end
