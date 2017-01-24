defmodule PhoenixSwagger.Test.Schemas.Car do
  use PhoenixSwagger.SchemaDefinition

  swagger_schema do
    color :string, "Color", required: true
    driver {:ref, :User}, required: true
    passenger {:ref, :User}
  end
end
