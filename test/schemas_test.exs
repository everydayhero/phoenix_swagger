defmodule PhoenixSwagger.JsonSchemaTest do
  use ExUnit.Case
  alias PhoenixSwagger.Schema
  alias PhoenixSwagger.Test.Schemas.{User,Book}
  import PhoenixSwagger

  swagger_definitions do
    [
      User: User.schema,
      Book: Book.schema,
    ]
  end

  test "produces a User definition" do
    user_schema = swagger_definitions["User"]

    assert user_schema == %{
      "type" => "object",
      "required" => [],
      "properties" => %{
        "full_name" => %{
          "description" => "Full name",
          "type" => "string"
        }
      }
    }
  end

  test "produces a Book definition" do
    book_schema = swagger_definitions["Book"]

    assert book_schema == %{
      "type" => "object",
      "required" => ["title", "author"],
      "properties" => %{
        "title" => %{
          "description" => "Title",
          "type" => "string"
        },
        "author" => %{
          "description" => "Author",
          "type" => "string"
        }
      }
    }
  end
end
