defmodule PhoenixSwagger.JsonApiTest do
  use ExUnit.Case
  use PhoenixSwagger

  doctest PhoenixSwagger.JsonApi

  swagger_definitions do
    JsonApi.resource(:User, :Users) do
      description "A user that may have one or more supporter pages."
      attributes do
        user_updated_at :string, "Last update timestamp UTC"
        user_created_at :string, "First created timestamp UTC"
        street_address :string, "Street address"
        region :string, "The users region"
        postal_code :string, "The users postal / zip code"
        phone :string, "Users phone number"
        locality :string, "???"
        full_name :string, "Full name"
        extended_address :string, "Extended address"
        email :string, "Email"
        country :string, "Country"
        birthday :string, "Birthday in YYYY-MM-DD format"
      end
    end
  end

  test "produces expected paginated users schema" do
    users_schema = swagger_definitions["Users"]
    assert users_schema == %{
      "description" => "A page of [User](#user) results",
      "properties" => %{
        "data" => %{
          "description" => "Content with [User](#user) objects",
          "items" => %{"$ref" => "#/definitions/User"},
          "type" => "array"
        },
        "links" => %{
          "properties" => %{
            "first" => %{"description" => "Link to the first page of results", "type" => "string"},
            "last" => %{"description" => "Link to the last page of results", "type" => "string"},
            "next" => %{"description" => "Link to the next page of results", "type" => "string"},
            "prev" => %{"description" => "Link to the previous page of results", "type" => "string"},
            "self" => %{"description" => "Link to this page of results", "type" => "string"}
          },
          "required" => ["self", "prev", "next", "last", "first"],
          "type" => "object"
        },
        "meta" => %{
          "properties" => %{
            "total-pages" => %{
              "description" => "The total number of pages available", "type" => "integer"
            }
          },
          "required" => ["total-pages"],
          "type" => "object"
        }
      },
      "required" => ["meta", "links", "data"],
      "type" => "object"
    }
  end

  test "produces expected user resource schema" do
    users_schema = swagger_definitions["User"]
    assert users_schema == %{
      "description" => "A user that may have one or more supporter pages.",
      "properties" => %{
        "attributes" => %{
          "properties" => %{
            "birthday" => %{ "description" => "Birthday in YYYY-MM-DD format", "type" => "string"},
            "country" => %{"description" => "Country", "type" => "string"},
            "email" => %{"description" => "Email", "type" => "string"},
            "extended_address" => %{"description" => "Extended address", "type" => "string"},
            "full_name" => %{"description" => "Full name", "type" => "string"},
            "locality" => %{"description" => "???", "type" => "string"},
            "phone" => %{"description" => "Users phone number", "type" => "string"},
            "postal_code" => %{"description" => "The users postal / zip code", "type" => "string"},
            "region" => %{"description" => "The users region", "type" => "string"},
            "street_address" => %{"description" => "Street address", "type" => "string"},
            "user_created_at" => %{"description" => "First created timestamp UTC", "type" => "string"},
            "user_updated_at" => %{"description" => "Last update timestamp UTC", "type" => "string"}
          },
          "type" => "object"
        }
      },
      "type" => "object"
    }
  end
end
