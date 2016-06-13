defmodule PhoenixSwagger.Schema do
  @moduledoc """
  Struct and helpers for swagger schema
  """

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
      %PhoenixSwagger.Schema{'$ref': "#/definitions/#{name}"}
    end
    def ref(path) when is_binary(path) do
      %PhoenixSwagger.Schema{'$ref': path}
    end

    def description(model = %PhoenixSwagger.Schema{}, desc) do
      %{model | description: desc}
    end
end
