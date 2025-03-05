defmodule GeoSpatialite do
  alias GeoSpatialite.{Decoder, Encoder}

  @moduledoc """
  Implements encoding and decoding for SpatiaLite geometries.

  SpatiaLite geometries are a slightly modified form of the well-known
  binary (WKB) format.
  """

  def decode!(wkb) do
    Decoder.decode(wkb)
  end

  def decode(wkb) do
    {:ok, decode!(wkb)}
  rescue
    exception ->
      {:error, exception}
  end

  def encode!(geom, endian \\ :little) do
    geom
    |> Encoder.encode!(endian)
    |> IO.iodata_to_binary()
  end

  def encode(geom, endian \\ :little) do
    {:ok, encode!(geom, endian)}
  rescue
    exception ->
      {:error, exception}
  end
end
