class PostgresqlConnectionFactory
  attr_reader :psql_ip, :psql_user

  def initialize
    @psql_ip = ENV['POSTGRESQL_HOST'] || 'localhost'
    @psql_user, @psql_pass = ENV["POSTGRES_CREDENTIALS"].split(':')
  end

  def create_connection(dbname:)
    psql_user = @psql_user || 'postgres'
    psql_ip = @psql_ip 
    dbname = dbname || 'postgres'
    password = @psql_pass
    PG.connect(password: password, user: psql_user, dbname: dbname, host: psql_ip)
  end

  def psql_configs
    { host: @psql_ip,
      port: '5432',
      user: @psql_user,
      passwd: @psql_pass,
      dbtype: 'postgis'}
  end
end
