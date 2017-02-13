class OpenLayerHandler
  attr_reader :geoserver

  delegate :perform_postgres_query, :hostname, :write_to_logfile, to: :geoserver, :allow_nil => true

  def initialize(geoserver)
    @geoserver = geoserver
  end

  def process
    "Implement process method"
  end
end