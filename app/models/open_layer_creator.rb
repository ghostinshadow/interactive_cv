class OpenLayerCreator < OpenLayerHandler
  VALUE_ZERO = 0

  def initialize(geoserver)
    super
  end

  def process(hsh = {})
    layer_prototype = OpenLayer.find_by(id: hsh.fetch(:layer_id))
    create_layer(layer_prototype.to_layer_data)
    layer_prototype.update_column(:exists, true) if layer_prototype
  end
  
  def create_layer layer_data
    return unless layer_data
    ws_from_prototype = find_or_create_workspace(ws_name: layer_data.ws)
    write_to_logfile(ws_from_prototype)
    return unless ws_from_prototype
    storage_from_prototype = find_or_create_store(layer_data)
    write_to_logfile(storage_from_prototype)
    return unless storage_from_prototype
    create_db_if_missing(db_name: layer_data.db_name)
    unless geoserver.data_exist_in_db?(db_name: layer_data.db_name, table_name: layer_data.layer_name)
      import_data_to_postgis_table(layer_data)
    end
    layer_from_prototype = find_or_create_layer(layer_data)
    write_to_logfile(layer_from_prototype)
    layer_from_prototype
  end

  private

  def find_or_create_layer(layer_data)
    filter = -> (layer) { layer["name"] == layer_data.layer_name}
    config_factory = GeoserverLayerConfigFactory.new
    layer_data.hostname = hostname
    init_data = config_factory.create_configuration(layer_data)
    find_or_create_resource(get_url: "#{hostname}/geoserver/api/layers/#{layer_data.ws}", path_to_coll: 'layers',
      post_url: "#{hostname}/geoserver/api/layers/#{layer_data.ws}", data: init_data, &filter)
  end


  def create_db_if_missing db_name:
    num_of_dbs_with_given_name = perform_postgres_query{|conn|
      query_res = conn.exec_params("SELECT 1 AS result FROM pg_database WHERE datname=$1", [db_name])
      query_res.values.flatten.first
    }.to_i
  
    return unless num_of_dbs_with_given_name == VALUE_ZERO 
    perform_postgres_query{|conn| conn.exec("create database #{conn.quote_ident(db_name)}")}
    perform_postgres_query(database: db_name){|conn| conn.exec('create extension postgis') } 
  end

  def import_data_to_postgis_table(layer_data)
    preparations = ShapefileImportPreparations.new({file_path: layer_data.file_path})
    preparations.perform
    shapefile = preparations.path_to_shapefile
    return unless shapefile
    %x{ shp2pgsql -s 4326 -W 'latin1' #{shapefile.shellescape}  public.#{layer_data.layer_name.shellescape} | psql -U #{geoserver.psql_user.shellescape} -h #{geoserver.psql_ip.shellescape} -p 5432 -d #{layer_data.db_name.shellescape} }
    FileUtils.rm_rf(preparations.path_to_unzipped_data)
  end

  def find_or_create_workspace(ws_name:)
    filter = -> (ws) { ws["name"] == ws_name}
    init_data = {name: ws_name,
                 uri: "http://geoserver.org/#{ws_name}",
                 default: false}
    find_or_create_resource(get_url: "#{hostname}/geoserver/api/workspaces", post_url: "#{hostname}/geoserver/api/workspaces", data: init_data, &filter)
  end

  def find_or_create_store(layer_data)
    filter = -> (store){ store['name'] == layer_data.storage_name }
    config_factory = GeoserverPostgisConfigFactory.new
    init_data = config_factory.create_configuration(layer_data)

    find_or_create_resource(get_url: "#{hostname}/geoserver/api/stores/#{layer_data.ws}", path_to_coll: "stores",
                            post_url: "#{hostname}/geoserver/rest/workspaces/#{layer_data.ws}/datastores", data: init_data, &filter)
    find_resource(url: "#{hostname}/geoserver/api/stores/#{layer_data.ws}", path_to_coll: "stores", &filter)
  end

  def find_or_create_resource(get_url: , post_url: nil, data:, path_to_coll: nil, &filter)
    resource = find_resource(url: get_url, path_to_coll: path_to_coll, &filter)
    return resource if resource
    request = geoserver.post_resource(url: post_url, data: data)
    JSON.parse(request.body || '')
  rescue JSON::ParserError
  end

  def find_resource(url:, path_to_coll: nil, &filter)
    resource_collection = geoserver.get_resource(url: url, path_to_collection: path_to_coll)
    filtered = resource_collection.select(&filter)
    filtered.first
  end

end