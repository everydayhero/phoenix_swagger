defmodule PhoenixSwagger.Test.Schemas.Car do
  use PhoenixSwagger.SchemaDefinition

  swagger_schema do
    color :string, "Color", required: true
    engine {:ref, :Engine}, required: true
    driver {:ref, :User}
    passengers {:array, :User}, "Passengers in car"
    wheels {:array, :Wheel}, required: true
    cargo {:array, :Luggage}
  end
end
