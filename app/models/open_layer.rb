class OpenLayer < ApplicationRecord

  mount_uploader :shapefile_archive, ShapefileArchiveUploader

  validates_length_of :name, maximum: 70
  validates_length_of [:workspace_name, :db_name], maximum: 50
  validates_length_of :description, maximum: 200
  validates_presence_of :workspace_name, :db_name, :name
  validates_format_of [:db_name, :workspace_name, :name], with: /\w/

  after_save :publish_layer
  before_destroy :delete_layer

  def self.to_json(properties: [:id, :name, :workspace_name, :db_name, :description, :exists])
    all.map { |l|
      properties.inject({}){|h, prop| h[prop] = l.send(prop); h}
    }.to_json
  end

  def self.imported_layers
    coordinates = GeoCoordinates.new
    geoserver = Geoserver.new
    hash_with_layers_data =  geoserver.fetch_layers(ws: "imported_layers")
    return hash_with_layers_data if hash_with_layers_data[:coordinates].any?
    hash_with_layers_data.merge({coordinates: coordinates.to_a})
  end

  def file_for_import_path
    shapefile_archive.path
  end

  def to_layer_data
    LayerData.new({ ws: workspace_name,
                    layer_name: name,
                    db_name: db_name,
                    file_path: file_for_import_path})
  end

  private

  def publish_layer
    Resque.enqueue(GeoserverTask, :create_layer, {layer_id: id})
  end

  def delete_layer
    Resque.enqueue(GeoserverTask, :destroy_layer, {ws: workspace_name, layer_name: name, db_name: db_name})
  end
end
