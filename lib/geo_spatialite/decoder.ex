defmodule GeoSpatialite.Decoder do
  @moduledoc false

  # these numbers can be referenced against postgis.git/doc/ZMSgeoms.txt
  @point 0x00_00_00_01
  # @point_m 0x40_00_00_01
  # @point_z 0x80_00_00_01
  # @point_zm 0xC0_00_00_01
  @line_string 0x00_00_00_02
  # @line_string_z 0x80_00_00_02
  # @line_string_zm 0xC0_00_00_02
  @polygon 0x00_00_00_03
  # @polygon_z 0x80_00_00_03
  # @multi_point 0x00_00_00_04
  # @multi_point_z 0x80_00_00_04
  # @multi_line_string 0x00_00_00_05
  # @multi_line_string_z 0x80_00_00_05
  @multi_polygon 0x00_00_00_06
  # @multi_polygon_z 0x80_00_00_06
  # @geometry_collection 0x00_00_00_07

  alias Geo.{
    Point,
    LineString,
    Polygon,
    MultiPolygon
  }

  for {endian, modifier} <- [{1, quote(do: little)}, {0, quote(do: big)}] do
    def decode(
          <<0, unquote(endian)::unquote(modifier)-integer-unsigned, srid::32-unquote(modifier),
            _x_min::unquote(modifier)-float-64, _y_min::unquote(modifier)-float-64,
            _x_max::unquote(modifier)-float-64, _y_max::unquote(modifier)-float-64, 124,
            type::unquote(modifier)-32, rest::bits>>
        ) do
      {geo, <<254>>} = do_decode(type, rest, srid, unquote(endian))
      geo
    end

    def do_decode(
          @point,
          <<x::unquote(modifier)-float-64, y::unquote(modifier)-float-64, rest::bits>>,
          srid,
          unquote(endian)
        ) do
      {%Point{coordinates: {x, y}, srid: srid}, rest}
    end

    def do_decode(
          @line_string,
          <<count::unquote(modifier)-32, rest::bits>>,
          srid,
          unquote(endian)
        ) do
      {coordinates, rest} =
        Enum.map_reduce(1..count, rest, fn _,
                                           <<x::unquote(modifier)-float-64,
                                             y::unquote(modifier)-float-64, rest::bits>> ->
          {%Point{coordinates: coordinates}, _rest} =
            do_decode(
              @point,
              <<x::unquote(modifier)-float-64, y::unquote(modifier)-float-64>>,
              nil,
              unquote(endian)
            )

          {coordinates, rest}
        end)

      {%LineString{coordinates: coordinates, srid: srid}, rest}
    end

    def do_decode(
          @polygon,
          <<count::unquote(modifier)-32, rest::bits>>,
          srid,
          unquote(endian)
        ) do
      {coordinates, rest} =
        Enum.map_reduce(1..count, rest, fn _, <<rest::bits>> ->
          {%LineString{coordinates: coordinates}, rest} =
            do_decode(
              @line_string,
              rest,
              nil,
              unquote(endian)
            )

          {coordinates, rest}
        end)

      {%Polygon{coordinates: coordinates, srid: srid}, rest}
    end

    def do_decode(
          @multi_polygon,
          <<count::unquote(modifier)-32, rest::bits>>,
          srid,
          unquote(endian)
        ) do
      {coordinates, rest} =
        Enum.map_reduce(1..count, rest, fn _, <<rest::bits>> ->
          <<105, @polygon::unquote(modifier)-32, rest::bits>> = rest

          {%Polygon{coordinates: coordinates}, rest} =
            do_decode(@polygon, rest, nil, unquote(endian))

          {coordinates, rest}
        end)

      {%MultiPolygon{coordinates: coordinates, srid: srid}, rest}
    end
  end
end
