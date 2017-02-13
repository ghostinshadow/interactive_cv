class GeoserverLayerConfigFactory
  def initialize
    @layer_defaults = {
      proj: default_projection,
      projectionExtent: default_projection_extent,
    geometry: "MultiLineString"}
  end


  def create_configuration(layer_data)
    {
      name: layer_data.layer_name,
      workspace: layer_data.ws,
      title: layer_data.layer_name,
      type: "vector",
      resource: {
        workspace: layer_data.ws,
        name: layer_data.layer_name,
        store: layer_data.storage_name,
        url: "#{layer_data.hostname}/geoserver/api/stores/#{layer_data.ws}/#{layer_data.storage_name}/#{layer_data.layer_name}"
      },
      style: {
        name: "line"
      },
      keywords: [
        "features",
        layer_data.layer_name
      ]
    }.merge(@layer_defaults)
  end

  private

  def default_projection
    {
      wkt: "GEOGCS[\"WGS 84\", \n  DATUM[\"World Geodetic System 1984\", \n    SPHEROID[\"WGS 84\", 6378137.0, 298.257223563, AUTHORITY[\"EPSG\",\"7030\"]], \n    AUTHORITY[\"EPSG\",\"6326\"]], \n  PRIMEM[\"Greenwich\", 0.0, AUTHORITY[\"EPSG\",\"8901\"]], \n  UNIT[\"degree\", 0.017453292519943295], \n  AXIS[\"Geodetic longitude\", EAST], \n  AXIS[\"Geodetic latitude\", NORTH], \n  AUTHORITY[\"EPSG\",\"4326\"]]",
      unit: "degrees",
      srs: "EPSG:4326",
      title: "WGS 84",
      type: "geographic"
    }
  end

  def default_projection_extent
    {
      east: 180,
      south: -90,
      north: 90,
      center: [
        0,
        0
      ],
      west: -180
    }
  end
end
