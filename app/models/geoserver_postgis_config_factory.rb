class GeoserverPostgisConfigFactory
  attr_reader :postgresql_factory
  
  def initialize
    @postgresql_factory = PostgresqlConnectionFactory.new
    @storage_defaults = {"schema"=>"public", "Estimated extends"=>true,
                         "fetch size"=>1000, "Expose primary keys"=>false, "validate connections"=>true,
                         "Support on the fly geometry simplification"=>true, "create database"=>true,
                         "Max connection idle time"=>300, "Test while idle"=>true, "Evictor tests per run"=>3,
                         "max connections"=>10, "min connections"=>1, "Connection timeout"=>20,
                         "Evictor run periodicity"=>300, "Max open prepared statements"=>50,
                         "encode functions"=>false, "preparedStatements"=>false, "Loose bbox"=>true}
  end

  def create_configuration(layer_data)
    {
      dataStore: {
        name: layer_data.storage_name,
        enabled: true,
        workspace: layer_data.ws,
        connectionParameters: {
          database: layer_data.db_name
        }.merge(default_configurations)
      }
    }
  end

  def default_configurations
    postgresql_factory.psql_configs.merge(@storage_defaults)
  end
end
