[![Build Status](https://travis-ci.org/everydayhero/phoenix_swagger.svg?branch=master)](https://travis-ci.org/everydayhero/phoenix_swagger)
[![Hex Version](https://img.shields.io/hexpm/v/edh_phoenix_swagger.svg)](https://hex.pm/packages/edh_phoenix_swagger)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg)](https://hexdocs.pm/edh_phoenix_swagger/)
[![License](https://img.shields.io/hexpm/l/edh_phoenix_swagger.svg)](https://github.com/everydayhero/phoenix_swagger/blob/master/LICENSE)
[![Inline docs](http://inch-ci.org/github/everydayhero/phoenix_swagger.svg?branch=master&style=shields)](http://inch-ci.org/github/everydayhero/phoenix_swagger)

# PhoenixSwagger

`PhoenixSwagger` is the library that provides [swagger](http://swagger.io/) integration
to the [phoenix](http://www.phoenixframework.org/) web framework.

## Installation

`PhoenixSwagger` provides the `phoenix.swagger.generate` mix task for generating the `swagger-ui` `json` file. This file contains the `swagger` specification that describes the API of your `Phoenix` application.

To use `PhoenixSwagger` within a `Phoenix` application, just add it to your dependencies in the `mix.exs` file:

```elixir
def deps do
  [{:edh_phoenix_swagger, "~> 0.1.8"}]
end
```

Now you can use `phoenix_swagger` to generate the `swagger-ui` json file for your application.

## Usage

You must define the `swagger_spec/0` function in your `router.ex` file. This function must
return a map that contains the structure of a [swagger object](http://swagger.io/specification/#swaggerObject)
This defines the skeleton of your swagger spec, with the `paths` and `definitions` sections being filled in by `phoenix_swagger`.

```elixir
def swagger_spec do
  %{
    swagger: "2.0",
    info: %{
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
      "application/json"
    ],
    produces: [
      "application/json"
    ],
    definitions: %{},
    paths: %{},
  }
end
```

`PhoenixSwagger` provides the `swagger_path/2` macro that generates `swagger` documentation that you can use in your controllers.

Example:

```elixir
defmodule MyApp.UserController do
  use MyApp.Web, :controller
  import PhoenixSwagger

  swagger_path :index do
    get "/users"
    summary "Get users"
    description "Get all users"
    response 200, "Success", :Users
    tag "users"
  end

  def index(conn, _params) do
    posts = Repo.all(MyApp.User)
    render(conn, "index.json", posts: posts)
  end

  swagger_path :show do
    get "/users/{id}"
    summary "Get single user"
    description "Get a single user by id"
    parameter :id, :path, :integer, "account id", required: true
    response 200, "Success", :User
    tag "users"
  end

  def show(conn, _params) do
    user = Repo.get!(MyApp.User, id)
    render(conn, "show.json", user: user)
  end
end
```

The `swagger_path` macro takes two parameters:

* The name of the controller action
* A `do` block containing calls into the `PhoenixSwagger.Path` module.

The body of the DSL is only a thin layer of syntax sugar over a regular `Phoenix` function pipeline.
The example above can be rewritten as:

```elixir
def swagger_path_index do
  import Phoenix.Swagger.Path
  get("/users")
  |> description("Short description")
  |> parameter(:id, :query, :integer, "Property id", required: true)
  |> response(200, "Description")
  |> nest
  |> to_json
end
```

The `do` bock always starts with one of the `get`, `put`, `post`, `delete`, `head`, `options` functions. This creates a new `#SwaggerPath{}` struct to pipe it through the remaining functions.

It is recommended that you supply the documentation fields `summary`, `description`, `parameter`, and `response`.

The `parameter` option provides the description of a parameter for the given action and may take four positional arguments, and a keyword list of optional arguments:

* The name of the parameter. [required];
* The location of the parameter. Possible values are `query`, `header`, `path`, `formData` or `body`. [required];
* The type of the parameter. Allowed [swagger data types](https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md#data-types
) [required];
* Description of a parameter. Can be an Elixir `String` or `function/0` that returns an Elixir string;
* Keyword parameters can use any attribute from the [swagger parameter spec](http://swagger.io/specification/#parameterObject), and additionally can use `required: true` to indicate that the parameter is mandatory.

Responses provide a status code, a description and an optional schema.
The simplest way to provide a schema is to use the `Schema.ref/1` helper function.

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

This example adds 3 entries to the [definitions](http://swagger.io/specification/#definitionsObject) section of the swagger document.

* `User`: A JSON-API Response containing a single user
* `Users`: for paginated responses with links to `next`, `prev`, `first`, `last` pages.
* `UserResource`: The schema of the data object appearing in a `User` response, or each item of a `Users` response.

Each line in the attributes block should contain `name`, `type`, `description`, `keyword-args`.
The keyword args can contain any [Schema Object](http://swagger.io/specification/#schemaObject) fields.

Schemas can also be defined outside of a `swagger_definitions` using `swagger_schema`.

```elixir
defmodule Example.Schema.User do
  use PhoenixSwagger.SchemaDefinition

  swagger_schema do
    full_name, :string, "Full name"
    email, :string, "Title", required: true
    favorite_pizza, :string, "Favorite pizza", enum: [:pepperoni, :cheese, :supreme]
    birthday, :datetime, "Birthday", format: :datetime
    address {:ref, :Address}, required: true
  end
end
```

The schema can then be added to the schema definitions for swagger.

```elixir
swagger_definitions do
  User: Example.Schema.User.schema
end
```

After this, run:

```
mix phoenix.swagger.generate
```

This will generate the `swagger.json` file that is used by `swagger-ui` at the root directory of your `phoenix` application.
To generate the `swagger.json` file with a custom name / path, pass the path + name to the mix task using `-o` or `--output` flags:

```
mix phoenix.swagger.generate -o ~/my-phoenix-api.json
```

If you have more than one router in your project, the `-r` or `--router` flags can be used:

```
mix phoenix.swagger.generate -o ~/my-phoenix-api.json -r MyApp.Router
```

For more information, check the `swagger` specification [here](https://github.com/swagger-api/swagger-spec/blob/master/versions/2.0.md).
