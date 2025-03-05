defmodule GeoSpatialite.Encoder do
  @moduledoc false

  # https://www.gaia-gis.it/gaia-sins/BLOB-Geometry.html
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

  def header(srid, :little) do
    <<0::size(8), 1::size(8), srid::little-32>>
  end

  def header(srid, :big) do
    <<0::size(8), 0::size(8), srid::big-32>>
  end

  def encode!(geom, endian \\ :little)

  def do_encode(%Point{coordinates: nil}, :little) do
    {@point, [<<00, 00, 00, 00, 00, 00, 248, 127>>, <<00, 00, 00, 00, 00, 00, 248, 127>>]}
  end

  def do_encode(%Point{coordinates: nil}, :big) do
    {@point, [<<127, 248, 00, 00, 00, 00, 00, 00>>, <<127, 248, 00, 00, 00, 00, 00, 00>>]}
  end

  for {endian_atom, modifier} <- [{:little, quote(do: little)}, {:big, quote(do: big)}] do
    def encode!(geom, unquote(endian_atom)) do
      {type, {x_min, y_min, x_max, y_max}, rest} = do_encode(geom, unquote(endian_atom))

      mbr_segment =
        <<x_min::unquote(modifier)-float-64, y_min::unquote(modifier)-float-64,
          x_max::unquote(modifier)-float-64, y_max::unquote(modifier)-float-64>>

      header =
        if geom.srid do
          header(geom.srid, unquote(endian_atom))
        else
          header(0, unquote(endian_atom))
        end

      [header, mbr_segment, 124, <<type::unquote(modifier)-32>>, rest, 254]
    end

    def do_encode(%Point{coordinates: {x, y}}, unquote(endian_atom)) do
      {@point, {x, y, x, y},
       [<<x::unquote(modifier)-float-64>>, <<y::unquote(modifier)-float-64>>]}
    end

    def do_encode(%LineString{coordinates: coordinates}, unquote(endian_atom)) do
      init = {0, {nil, nil, nil, nil}}

      {coordinates, {count, mbr}} =
        Enum.map_reduce(coordinates, init, fn {x, y}, {count, mbr} ->
          state =
            {count + 1, update_mbr({x, y}, mbr)}

          {[<<x::unquote(modifier)-float-64>>, <<y::unquote(modifier)-float-64>>], state}
        end)

      {@line_string, mbr, [<<count::unquote(modifier)-32>> | coordinates]}
    end

    def do_encode(%Polygon{coordinates: coordinates}, unquote(endian_atom)) do
      init = {0, {nil, nil, nil, nil}}

      {coordinates, {count, mbr}} =
        Enum.map_reduce(coordinates, init, fn ring, {count, current_mbr} ->
          {_, mbr, data} = do_encode(%LineString{coordinates: ring}, unquote(endian_atom))
          state = {count + 1, update_mbr(mbr, current_mbr)}
          {data, state}
        end)

      {@polygon, mbr, [<<count::unquote(modifier)-32>> | coordinates]}
    end

    def do_encode(%MultiPolygon{coordinates: coordinates}, unquote(endian_atom)) do
      init = {0, {nil, nil, nil, nil}}

      {coordinates, {count, mbr}} =
        Enum.map_reduce(coordinates, init, fn polygon, {count, current_mbr} ->
          {_, mbr, data} = do_encode(%Polygon{coordinates: polygon}, unquote(endian_atom))
          state = {count + 1, update_mbr(mbr, current_mbr)}
          {[105, <<@polygon::unquote(modifier)-32>>, data], state}
        end)

      {@multi_polygon, mbr, [<<count::unquote(modifier)-32>> | coordinates]}
    end
  end

  def update_mbr({x_min, y_min, x_max, y_max}, {nil, nil, nil, nil}) do
    {x_min, y_min, x_max, y_max}
  end

  def update_mbr({x_min1, y_min1, x_max1, y_max1}, {x_min2, y_min2, x_max2, y_max2}) do
    x_min = Enum.min([x_min1, x_min2])
    y_min = Enum.min([y_min1, y_min2])
    x_max = Enum.max([x_max1, x_max2])
    y_max = Enum.max([y_max1, y_max2])

    {x_min, y_min, x_max, y_max}
  end

  def update_mbr({x, y}, {nil, nil, nil, nil}) do
    {x, y, x, y}
  end

  def update_mbr({x, y}, {x_min, y_min, x_max, y_max}) do
    x_min = Enum.min([x_min, x])
    y_min = Enum.min([y_min, y])
    x_max = Enum.max([x_max, x])
    y_max = Enum.max([y_max, y])

    {x_min, y_min, x_max, y_max}
  end
end
