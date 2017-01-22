defmodule PhoenixSwagger.Test.Schemas.User do
  use PhoenixSwagger.SchemaDefinition

  swagger_schema do
    full_name :string, "Full name"
  end
end
