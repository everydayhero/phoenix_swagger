defmodule PhoenixSwagger.Path do
  @moduledoc """
  Defines the swagger path DSL for specifying Controller actions.
  This module should not be imported directly, it will be automatically imported
   in the scope of a `swagger_path` macro body.

  ## Examples

      use PhoenixSwagger

      swagger_path :index do
        get "/users"
        produces "application/json"
        paging
        parameter :id, :query, :integer, "user id", required: true
        tag "Users"
        response 200 "User resource" :User
        response 404 "User not found"
      end
  """

  alias PhoenixSwagger.Schema

  defmodule Parameter do
    @moduledoc """
    A swagger parameter definition, similar to a Schema, but swagger Defines
    parameter name (and some other options) to be part of the parameter object itself.
    """

    defstruct(
      name: "",
      in: "",
      description: "",
      required: false,
      schema: nil,
      type: nil,
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
    @moduledoc """
    A swagger response definition.
    The response status (200, 404, etc.) is the key in the containing map.
    """
    defstruct description: "", schema: nil, headers: nil, examples: nil
  end

  defmodule OperationObject do
    @moduledoc """
    A swagger operation object ties together parameters, responses, etc.
    """
    defstruct(
      tags: [],
      summary: "",
      description: "",
      externalDocs: nil,
      operationId: "",
      consumes: nil,
      produces: nil,
      parameters: [],
      responses: %{},
      deprecated: nil,
      security: nil)
  end

  defmodule PathObject do
    @moduledoc """
    The DSL builds paths out of individual operations, so this is a flattened version
    of a swagger Path. The nest function will convert this to a nested map before final
    conversion to a JSON map.
    """
    defstruct path: "", verb: "", operation: %OperationObject{}
  end

  @doc "Initializes a Swagger Path DSL block with a get verb"
  def get(path), do: %PathObject{path: path, verb: "get"}

  @doc "Initializes a Swagger Path DSL block with a post verb"
  def post(path), do: %PathObject{path: path, verb: "post"}

  @doc "Initializes a Swagger Path DSL block with a put verb"
  def put(path), do: %PathObject{path: path, verb: "put"}

  @doc "Initializes a Swagger Path DSL block with a delete verb"
  def delete(path), do: %PathObject{path: path, verb: "delete"}

  @doc "Initializes a Swagger Path DSL block with a head verb"
  def head(path), do: %PathObject{path: path, verb: "head"}

  @doc "Initializes a Swagger Path DSL block with a options verb"
  def options(path), do: %PathObject{path: path, verb: "options"}


  @doc """
  Adds the summary section to the operation of a swagger `%PathObject{}`
  """
  def summary(path = %PathObject{}, summary) do
    put_in path.operation.summary, summary
  end

  @doc """
  Adds the description section to the operation of a swagger `%PathObject{}`
  """
  def description(path = %PathObject{}, description) do
    put_in path.operation.description, description
  end

  @doc """
  Adds a mime-type to the consumes list of the operation of a swagger `%PathObject{}`
  """
  def consumes(path = %PathObject{}, mimetype) do
    put_in path.operation.consumes, (path.operation.consumes || []) ++ [mimetype]
  end

  @doc """
  Adds a mime-type to the produces list of the operation of a swagger `%PathObject{}`
  """
  def produces(path = %PathObject{}, mimetype) do
    put_in path.operation.produces, (path.operation.produces || []) ++ [mimetype]
  end

  @doc """
  Adds a tag to the operation of a swagger `%PathObject{}`
  """
  def tag(path = %PathObject{}, tag) do
    put_in path.operation.tags, path.operation.tags ++ [tag]
  end

  @doc """
  Adds the operationId section to the operation of a swagger `%PathObject{}`
  """
  def operation_id(path = %PathObject{}, id) do
    put_in path.operation.operationId, id
  end

  @doc """
  Adds a parameter to the operation of a swagger `%PathObject{}`
  """
  def parameter(path = %PathObject{}, name, location, type, description, opts \\ []) do
    param = %Parameter{
      name: name,
      in: location,
      description: description
    }
    param = case location do
      :body -> %{param | schema: type}
      :path -> %{param | type: type, required: true}
      _ -> %{param | type: type}
    end
    param = Map.merge(param, opts |> Enum.into(%{}, &translate_parameter_opt/1))
    params = path.operation.parameters
    put_in path.operation.parameters, params ++ [param]
  end

  defp translate_parameter_opt({:example, v}), do: {:"x-example", v}
  defp translate_parameter_opt({:items, items_schema}) when is_list(items_schema) do
     {:items, Enum.into(items_schema, %{})}
  end
  defp translate_parameter_opt({k, v}), do: {k, v}

  @doc """
  Adds page size, number and offset parameters to the operation of a swagger `%PathObject{}`

  The names default to  "page[size]" and "page[number]", but can be overridden.

  ## Examples

      get "/api/pets/"
      paging
      response 200, "OK"

      get "/api/pets/dogs"
      paging size: "page_size", number: "count"
      response 200, "OK"

      get "/api/pets/cats"
      paging size: "limit", offset: "offset"
      response 200, "OK"
  """
  def paging(path = %PathObject{}, opts \\ [size: "page[size]", number: "page[number]"]) do
    Enum.reduce opts, path, fn
      {:size, size}, path -> parameter(path, size, :query, :integer, "Number of elements per page", minimum: 1)
      {:number, number}, path -> parameter(path, number, :query, :integer, "Number of the page", minimum: 1)
      {:offset, offset}, path -> parameter(path, offset, :query, :integer, "Offset of first element in the page")
    end
  end

  @doc """
  Adds a response to the operation of a swagger `%PathObject{}`, without a schema
  """
  def response(path = %PathObject{}, status, description) do
    resp = %ResponseObject{description: description}
    put_in path.operation.responses[status |> to_string], resp
  end

  @doc """
  Adds a response to the operation of a swagger `%PathObject{}`, with a schema

  Optional keyword args can be provided for `headers` and `examples`
  If the mime-type is known from the `produces` list, then a single can be given as a shorthand.

  ## Example

      get "/users/{id}"
      produces "application/json"
      parameter :id, :path, :integer, "user id", required: true
      response 200, "Success", :User, examples: %{"application/json": %{id: 1, name: "Joe"}}

      get "/users/{id}"
      produces "application/json"
      parameter :id, :path, :integer, "user id", required: true
      response 200, "Success", :User, example: %{id: 1, name: "Joe"}
  """
  def response(path, status, description, schema, opts \\ [])
  def response(path = %PathObject{}, status, description, schema, opts) when is_atom(schema)  do
    response(path, status, description, Schema.ref(schema), opts)
  end
  def response(path = %PathObject{}, status, description, schema = %Schema{}, opts) do
    opts = expand_response_example(path, opts)
    resp = struct(ResponseObject, [description: description, schema: schema] ++ opts)
    put_in path.operation.responses[status |> to_string], resp
  end

  def expand_response_example(%PathObject{operation: %{produces: [mimetype | _]}}, opts) do
    Enum.map(opts, fn
      {:example, e} -> {:examples, %{mimetype => e}}
      opt -> opt
    end)
  end

  @doc """
  Converts the `%PathObject{}` struct into the nested JSON form expected by swagger
  """
  def nest(path = %PathObject{}) do
    %{path.path => %{path.verb => path.operation}}
  end
end
