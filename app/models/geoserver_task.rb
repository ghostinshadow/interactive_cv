class GeoserverTask
  @queue = :geoserver_tasks

  def self.perform(method, args = {})
    args = args.with_indifferent_access
    Resque.logger.info("Perform GeoserverTask:" + method)
    Resque.logger.info(args)
    handler = HandlerFactory.new.create_handler(method)
    handler.process(args)
  end
end