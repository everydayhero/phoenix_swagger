defmodule PhoenixSwagger.Path do
  @moduledoc """
  Defines the swagger path DSL for specifying Controller actions.
  This module should not be imported directly, it will be automatically imported
   in the scope of a swagger_path macro body.

  ## Examples
    use PhoenixSwagger

    swagger_path :index do
      get "/users"
      produces "application/json"
      paging
      parameter :id, :query, :integer, "user id", :required
      tag "Users"
      response 200 "User resource" :User
      response 404 "User not found"
    end
  """

  alias PhoenixSwagger.Schema

  defmodule Parameter do
    defstruct(
      name: "",
      in: "",
      description: "",
      required: false,
      schema: nil,
      type: "",
      format: nil,
      allowEmptyValue: nil,
      items: nil,
      collectionFormat: nil,
      default: nil,
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
      multipleOf: nil)
  end

  defmodule ResponseObject do
    defstruct description: "", schema: nil, headers: nil, examples: nil
  end

  defmodule OperationObject do
    defstruct(
      tags: [],
      summary: "",
      description: "",
      externalDocs: nil,
      operationId: "",
      consumes: [],
      produces: [],
      parameters: [],
      responses: %{},
      deprecated: nil,
      security: nil)
  end

  defmodule PathObject do
    defstruct path: "", verb: "", operation: %OperationObject{}
  end

  @doc """
  Initializes a Swagger Path DSL block
  """
  def get(path) do
    %PathObject{path: path, verb: "get"}
  end

  @doc """
  Adds the summary section to the operation of a swagger %PathObject{}
  """
  def summary(path = %PathObject{}, summary) do
    put_in path.operation.summary, summary
  end

  @doc """
  Adds the description section to the operation of a swagger %PathObject{}
  """
  def description(path = %PathObject{}, description) do
    put_in path.operation.description, description
  end

  @doc """
  Adds a mime-type to the consumes list of the operation of a swagger %PathObject{}
  """
  def consumes(path = %PathObject{}, mimetype) do
    put_in path.operation.consumes, path.operation.consumes ++ [mimetype]
  end

  @doc """
  Adds a mime-type to the produces list of the operation of a swagger %PathObject{}
  """
  def produces(path = %PathObject{}, mimetype) do
    put_in path.operation.produces, path.operation.produces ++ [mimetype]
  end

  @doc """
  Adds a tag to the operation of a swagger %PathObject{}
  """
  def tag(path = %PathObject{}, tag) do
    put_in path.operation.tags, path.operation.tags ++ [tag]
  end

  @doc """
  Adds the operationId section to the operation of a swagger %PathObject{}
  """
  def operation_id(path = %PathObject{}, id) do
    put_in path.operation.operationId, id
  end

  @doc """
  Adds a parameter to the operation of a swagger %PathObject{}
  """
  def parameter(path = %PathObject{}, name, location, type, description, required? \\ false) do
    param = %Parameter{
      name: name,
      in: location,
      type: type,
      description: description,
      required: if required? do true else false end
    }
    params = path.operation.parameters
    put_in path.operation.parameters, params ++ [param]
  end

  @doc """
  Adds page size and page number parameters to the operation of a swagger %PathObject{}

  The names default to  "page[size]" and "page[number]", but can be overridden.
  """
  def paging(path = %PathObject{}, page_size_arg \\ "page[size]", page_num_arg \\ "page[number]") do
    path
    |> parameter(page_size_arg, :query, :integer, "Number of elements per page")
    |> parameter(page_num_arg, :query, :integer, "Number of the page")
  end

  @doc """
  Adds a response to the operation of a swagger %PathObject{}, without a schema
  """
  def response(path = %PathObject{}, status, description) do
    resp = %ResponseObject{description: description}
    put_in path.operation.responses[status |> to_string], resp
  end

  @doc """
  Adds a parameter to the operation of a swagger %PathObject{}, with a schema
  """
  def response(path = %PathObject{}, status, description, schema) when is_atom(schema)  do
    resp = %ResponseObject{description: description, schema: %{ "$ref" => "#/definitions/#{schema}" }}
    put_in path.operation.responses[status |> to_string], resp
  end
  def response(path = %PathObject{}, status, description, schema = %Schema{}) do
    resp = %ResponseObject{description: description, schema: schema}
    put_in path.operation.responses[status |> to_string], resp
  end

  @doc """
  Converts the %PathObject{} struct into the nested JSON form expected by swagger
  """
  def nest(path = %PathObject{}) do
    %{path.path => %{path.verb => path.operation}}
  end
end
