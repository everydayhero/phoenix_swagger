[![Build Status](https://travis-ci.org/everydayhero/phoenix_swagger.svg?branch=master)](https://travis-ci.org/everydayhero/phoenix_swagger)
[![Hex Version](https://img.shields.io/hexpm/v/edh_phoenix_swagger.svg)](https://hex.pm/packages/edh_phoenix_swagger)
[![License](https://img.shields.io/hexpm/l/edh_phoenix_swagger.svg)](https://github.com/everydayhero/phoenix_swagger/blob/master/LICENSE)
[![Inline docs](http://inch-ci.org/github/everydayhero/phoenix_swagger.svg?branch=master&style=shields)](http://inch-ci.org/github/everydayhero/phoenix_swagger)

# PhoenixSwagger

`PhoenixSwagger` is the library that provides [swagger](http://swagger.io/) integration
to the [phoenix](http://www.phoenixframework.org/) web framework.

## Installation

`PhoenixSwagger` provides `phoenix.swagger.generate` mix task for the swagger-ui `json`
file generation that contains swagger specification that describes API of the `phoenix`
application.

You just need to add the swagger DSL to your controllers and then run this one mix task
to generate the json files.

To use `PhoenixSwagger` with a phoenix application just add it to your list of
dependencies in the `mix.exs` file:

```elixir
def deps do
  [{:phoenix_swagger, "~> 0.0.1"}]
end
```

Now you can use `phoenix_swagger` to generate `swagger-ui` file for you application.

## Usage

You must provide `swagger_spec/0` function in your `Router.ex` file. This function must
return a map that contains the structure of a [swagger object](http://swagger.io/specification/#swaggerObject)
This defines the skeleton of your swagger spec, with the `paths` and `definitions` sections being filled in by phoenix_swagger.

```elixir
def swagger_spec do
  %{
    :swagger => "2.0",
    :info => %{
      version: "0.0.1",
      title: "My awesome phoenix project."
    },
    securityDefinitions: %{
      basic_auth: %{
        type: "basic",
        description: "Standard HTTP basic authentication applies to all API operations."
      }
    },
    security: [
      %{basic_auth: []}
    ],
    tags: [
      %{
        name: "users",
        description: "Operations related to users"
      }
    ],
    consumes: [
      "application/vnd.api+json"
    ],
    produces: [
      "application/vnd.api+json"
    ],
    definitions: %{},
    paths: %{},
  }
end
```

`PhoenixSwagger` provides `swagger_path/2` macro that generates swagger documentation
for the certain phoenix controller.

Example:

```elixir
use PhoenixSwagger

swagger_path :index do
  get "/users"
  summary "Get users"
  description "Get users, filtering by account ID"
  parameter :query, :id, :integer, "account id", required: true
  response 200, "Description", :Users
  tag "users"
end

def index(conn, _params) do
  posts = Repo.all(Post)
  render(conn, "index.json", posts: posts)
end
```

The `swagger_path` macro takes two parameters:

* The name of the controller action
* `do` block containing calls into the PhoenixSwagger.Path module.

The body of the DSL is only a thin layer of syntax sugar over a regular phoenix function pipeline.
The example above can be re-written as:

```elixir
def swagger_path_index do
  import Phoenix.Swagger.Path
  get("/users")
  |> description("Short description")
  |> parameter(:query, :id, :integer, "Property id", required: true)
  |> response(200, "Description")
  |> nest
  |> to_json
end
```

The `do` bock always starts with one of the `get`, `put`, `post`, `delete`, `head`, `options` functions. This creates a new `#SwaggerPath{}` struct to pipeline through the remaining functions.

At a minimum, you should probably supply `summary`, `description`, `parameter`, and `response` docs.

The `parameter` provides description of the routing parameter for the given action and
may take four positional parameters, and a keyword list of optional parameters:

* The location of the parameter. Possible values are `query`, `header`, `path`, `formData` or `body`. [required];
* The name of the parameter. [required];
* The type of the parameter. Allowed only [swagger data types](https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md#data-types
) [required];
* Description of a parameter. Can be elixir's `String` or function/0 that returns elixir's string;
* Keyword parameters can use any attribute from the [swagger parameter spec](http://swagger.io/specification/#parameterObject), and additionally can use `required: true` to indicate that the parameter is mandatory.

Responses supply a status code, description and optional schema.
The simplest way to supply a schema is to use the `Schema.ref/1` helper function.

```elixir
response 200, "Description", Schema.ref(:Post)
```

Schemas can be defined using the `swagger_definitions` macro.
Helpers are included for defining JSON-API style resources:

```elixir
swagger_definitions do
  JsonApi.resource(:User, :Users) do
    description "A user of the system."
    attributes do
      user_updated_at :string, "Last update timestamp UTC", format: "ISO-8601"
      user_created_at :string, "First created timestamp UTC"
      street_address :string, "Street address"
      email :string, "Email", required: true
    end
  end
end
```

This example adds two entries to the [definitions](http://swagger.io/specification/#definitionsObject) section of the swagger document.

* User: containing the declared attributes
* Users: for paginated responses with links to next, prev, first, last pages.

Each line in the attributes block should contain name, type, description, keyword-args.
The keyword args can contain any [Schema Object](http://swagger.io/specification/#schemaObject) fields.


That's all after this run the `phoenix.swagger.generate` mix task for the `swagger-ui` json
file generation into directory with `phoenix` application:

```
mix phoenix.swagger.generate
```

As the result there will be `swagger.json` file into root directory of the `phoenix` application.
To generate `swagger` file with the custom name/place, pass it to the main mix task:

```
mix phoenix.swagger.generate ~/my-phoenix-api.json
```

For more informantion, you can find `swagger` specification [here](https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md).
