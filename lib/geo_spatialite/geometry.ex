if Code.ensure_loaded?(Ecto.Type) do
  defmodule GeoSpatialite.Geometry do
    use Ecto.Type

    @moduledoc false

    @geometries [
      Geo.Point,
      Geo.LineString,
      Geo.Polygon,
      Geo.MultiPolygon
    ]

    def type, do: :binary

    def cast(%struct{} = geom) when struct in @geometries, do: {:ok, geom}
    def cast(_), do: :error

    def load(data) when is_binary(data) do
      case GeoSpatialite.decode(data) do
        {:error, _} ->
          :error

        {:ok, geo} ->
          {:ok, geo}
      end
    end

    def dump(%struct{} = geom) when struct in @geometries do
      GeoSpatialite.encode(geom)
    end

    def dump(_), do: :error
  end
end
