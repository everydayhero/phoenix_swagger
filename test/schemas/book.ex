defmodule PhoenixSwagger.Test.Schemas.Book do
  use PhoenixSwagger.SchemaDefinition

  swagger_schema do
    title :string, "Title", required: true
    author :string, "Author", required: true
  end
end
