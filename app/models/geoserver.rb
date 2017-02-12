class Geoserver
  @queue = :geoserver_tasks

  @hostname = ENV['HOST_DOMAIN_NAME'] || 'http://localhost:8080'
  @psql_ip = ENV['POSTGRESQL_HOST']
  @psql_user, @psql_pass = ENV["POSTGRESQL_CREDENTIALS"].split(':')

  def self.perform(method, args = {})
    args = args.with_indifferent_access
    write_to_logfile("Perform GeoserverTask:" + method)
    write_to_logfile(args)
    case method.to_sym
    when :create_layer then create_open_layer(args[:layer_id])
    when :destroy_layer then destroy_open_layer(ws: args[:ws], layer_name: args[:layer_name], db_name: args[:db_name])
    end
  end

  def self.fetch_layers(ws:)
    layers = GeoServerCommunicator.get_resource(url: "#{@hostname}/geoserver/api/layers/#{ws}", extension: false, path_to_collection: 'layers')
    coordinates = layers.first["bbox"]["lonlat"]["center"] if layers.first
    {layers: layers.map{|e| e.select_keys("name", "workspace")}, coordinates: coordinates || []}
  end

  def self.write_to_logfile(data)
    case data
    when String, Hash then Resque.logger.info(data)
    when Curl::Easy then Resque.logger.info(data.body)
    end
  end

  private

  def self.postgres_connection(database: nil)
    connection = PostgresqlConnectionFactory.create_connection({password: @psql_pass, user: @psql_user, psql_ip: @psql_ip, dbname: database})
    res = yield connection
    connection.close
    res
  end

  def self.create_open_layer id
    layer_prototype = OpenLayer.find_by(id: id)
    return unless layer_prototype
    ws_from_prototype = find_or_create_workspace(ws_name: layer_prototype.workspace_name)
    write_to_logfile(ws_from_prototype)
    return unless ws_from_prototype
    storage_from_prototype = find_or_create_store(ws: ws_from_prototype["name"],
                                                  storage_name: "#{layer_prototype.name}_store", db_name: layer_prototype.db_name)
    write_to_logfile(storage_from_prototype)
    return unless storage_from_prototype
    create_db_if_missing(db_name: layer_prototype.db_name)
    unless data_exist_in_db?(db_name: layer_prototype.db_name, table_name: layer_prototype.name)
      import_data_to_postgis_table(file_path: layer_prototype.file_for_import_path, db_name: layer_prototype.db_name, table_name: layer_prototype.name)
    end
    layer_from_prototype = find_or_create_layer(ws: ws_from_prototype["name"], storage_name: storage_from_prototype["name"], layer_name: layer_prototype.name)
    write_to_logfile(layer_from_prototype)
    layer_prototype.update_column(:exists, true)
  end

  def self.destroy_open_layer(ws: , layer_name:, db_name:)
    destroy_layer(ws: ws, layer_name: layer_name)
    destroy_db_table(db_name: db_name, table_name: layer_name)
    destroy_data_store(ws: ws, storage_name: "#{layer_name}_store")
  end

  def self.destroy_db_table(db_name: , table_name: )
    if data_exist_in_db? db_name: db_name, table_name: table_name
     command_out = postgres_connection(database: db_name){|conn|
       conn.exec("drop table #{conn.quote_ident(table_name)}")
     }
     write_to_logfile(command_out.values)
    end
  end

  def self.destroy_layer ws: , layer_name:
    response = GeoServerCommunicator.delete_resource(url: "#{@hostname}/geoserver/api/layers/#{ws}/#{layer_name}")
    write_to_logfile(response)
  end

  def self.destroy_data_store ws: , storage_name:
    response = GeoServerCommunicator.delete_resource(url: "#{@hostname}/geoserver/api/stores/#{ws}/#{storage_name}")
    write_to_logfile(response)
  end

  def self.find_or_create_layer(ws: , storage_name:, layer_name:)
    filter = -> (layer) { layer["name"] == layer_name}
    init_data = form_data_for_layer_creation(layer_name: layer_name, ws: ws, store: storage_name)
    find_or_create_resource(get_url: "#{@hostname}/geoserver/api/layers/#{ws}", path_to_coll: 'layers',
      post_url: "#{@hostname}/geoserver/api/layers/#{ws}", data: init_data, &filter)
  end

  def self.data_exist_in_db? db_name: , table_name:
    tables_in_database = postgres_connection(database: db_name){ |conn|
        query_res = conn.exec("SELECT * FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';")
        query_res.column_values(1)
      }
    tables_in_database.select{|e| e.match(/#{table_name}/)}.any?
  end

  def self.create_db_if_missing db_name:
    num_of_dbs_with_given_name = postgres_connection{|conn|
      query_res = conn.exec_params("SELECT 1 AS result FROM pg_database WHERE datname=$1", [db_name])
      query_res.values.flatten.first
    }.to_i
  
    return unless num_of_dbs_with_given_name == VALUE_ZERO 
    postgres_connection{|conn| conn.exec("create database #{conn.quote_ident(db_name)}")}
    postgres_connection(database: db_name){|conn| conn.exec('create extension postgis') } 
  end

  def self.import_data_to_postgis_table(file_path:, db_name:, table_name:)
    preparations = ShapefileImportPreparations.new({file_path: file_path})
    preparations.perform
    shapefile = preparations.path_to_shapefile
    return unless shapefile
    %x{ shp2pgsql -s 4326 -W 'latin1' #{shapefile.shellescape}  public.#{table_name.shellescape} | psql -U #{@psql_user.shellescape} -h #{@psql_ip.shellescape} -p 5432 -d #{db_name.shellescape} }
    FileUtils.rm_rf(preparations.path_to_unzipped_data)
  end

  def self.find_or_create_workspace(ws_name:)
    filter = -> (ws) { ws["name"] == ws_name}
    init_data = {name: ws_name,
                 uri: "http://geoserver.org/#{ws_name}",
                 default: false}
    find_or_create_resource(get_url: "#{@hostname}/geoserver/api/workspaces", post_url: "#{@hostname}/geoserver/api/workspaces", data: init_data, &filter)
  end

  def self.find_or_create_store(ws:, storage_name:, db_name:)
    filter = -> (store){ store['name'] == storage_name }
    init_data = form_data_for_store_creation(store_name: storage_name, ws: ws,
                                             db_name: db_name)
    find_or_create_resource(get_url: "#{@hostname}/geoserver/api/stores/#{ws}", path_to_coll: "stores",
                            post_url: "#{@hostname}/geoserver/rest/workspaces/#{ws}/datastores", data: init_data, &filter)
    find_resource(url: "#{@hostname}/geoserver/api/stores/#{ws}", path_to_coll: "stores", &filter)
  end

  def self.find_or_create_resource(get_url: , post_url: nil, data:, path_to_coll: nil, &filter)
    resource = find_resource(url: get_url, path_to_coll: path_to_coll, &filter)
    return resource if resource
    request = GeoServerCommunicator.post_resource(url: post_url, data: data, extension: false)
    JSON.parse(request.body || '')
  rescue JSON::ParserError
  end

  def self.find_resource(url:, path_to_coll: nil, &filter)
    resource_collection = GeoServerCommunicator.get_resource(url: url, extension: false, path_to_collection: path_to_coll)
    filtered = resource_collection.select(&filter)
    filtered.first
  end

  def self.form_data_for_store_creation(store_name: , ws:, db_name: )
    {
      dataStore: {
        name: store_name,
        enabled: true,
        workspace: ws,
        connectionParameters: {
          host: @psql_ip || 'localhost',
          port: '5432',
          database: db_name,
          user: @psql_user,
          passwd: @psql_pass,
          dbtype: 'postgis',
        }.merge(GEOSERVER_STORAGE_DEFAULTS)
      }
    }
  end


  def self.form_data_for_layer_creation(layer_name:, ws: , store:)
    {
      name: layer_name,
      workspace: ws,
      title: layer_name,
      type: "vector",
      resource: {
        workspace: ws,
        name: layer_name,
        store: store,
        url: "#{@hostname}/geoserver/api/stores/#{ws}/#{store}/#{layer_name}"
      },
      style: {
        name: "line"
      },
      keywords: [
        "features",
        layer_name
      ]
    }.merge(GEOSERVER_LAYER_DEFAULTS)
  end

end

GEOSERVER_STORAGE_DEFAULTS = {"schema"=>"public", "Estimated extends"=>true,
 "fetch size"=>1000, "Expose primary keys"=>false, "validate connections"=>true,
  "Support on the fly geometry simplification"=>true, "create database"=>true,
  "Max connection idle time"=>300, "Test while idle"=>true, "Evictor tests per run"=>3,
  "max connections"=>10, "min connections"=>1, "Connection timeout"=>20,
  "Evictor run periodicity"=>300, "Max open prepared statements"=>50,
  "encode functions"=>false, "preparedStatements"=>false, "Loose bbox"=>true}
GEOSERVER_LAYER_DEFAULTS = {
  proj: {
    wkt: "GEOGCS[\"WGS 84\", \n  DATUM[\"World Geodetic System 1984\", \n    SPHEROID[\"WGS 84\", 6378137.0, 298.257223563, AUTHORITY[\"EPSG\",\"7030\"]], \n    AUTHORITY[\"EPSG\",\"6326\"]], \n  PRIMEM[\"Greenwich\", 0.0, AUTHORITY[\"EPSG\",\"8901\"]], \n  UNIT[\"degree\", 0.017453292519943295], \n  AXIS[\"Geodetic longitude\", EAST], \n  AXIS[\"Geodetic latitude\", NORTH], \n  AUTHORITY[\"EPSG\",\"4326\"]]",
    unit: "degrees",
    srs: "EPSG:4326",
    title: "WGS 84",
    type: "geographic"
  },
  projectionExtent: {
    east: 180,
    south: -90,
    north: 90,
    center: [
      0,
      0
    ],
    west: -180
  },
geometry: "MultiLineString"}
NUMBER_OF_HEADERS_TO_SKIP = 3