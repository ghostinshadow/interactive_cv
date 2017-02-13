class Geoserver
  attr_reader :hostname, :communicator, :psql_conn_factory
  delegate :delete_resource, :post_resource, :get_resource, to: :communicator, :allow_nil => true
  delegate :psql_ip, :psql_user, to: :psql_conn_factory, allow_nil: true 

  def initialize
    @communicator = GeoServerCommunicator.new
    @psql_conn_factory = PostgresqlConnectionFactory.new
    @hostname = ENV['HOST_DOMAIN_NAME'] || 'http://localhost:8080'
  end


  def data_exist_in_db?(db_name: , table_name:)
    tables_in_database = perform_postgres_query(database: db_name){ |conn|
        query_res = conn.exec("SELECT * FROM pg_catalog.pg_tables WHERE schemaname != 'pg_catalog' AND schemaname != 'information_schema';")
        query_res.column_values(1)
      }
    tables_in_database.select{|e| e.match(/#{table_name}/)}.any?
  end

  def perform_postgres_query(database: nil)
    connection = psql_conn_factory.create_connection({dbname: database})
    res = yield connection
    connection.close
    res
  end

  def fetch_layers(ws:)
    layers = communicator.get_resource(url: "#{hostname}/geoserver/api/layers/#{ws}", path_to_collection: 'layers')
    coordinates = layers.first["bbox"]["lonlat"]["center"] if layers.first
    {layers: layers.map{|e| e.select_keys("name", "workspace")}, coordinates: coordinates || []}
  end

  def write_to_logfile(data)
    case data
    when String, Hash then Resque.logger.info(data)
    when Curl::Easy then Resque.logger.info(data.body)
    end
  end
end