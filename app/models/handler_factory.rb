class HandlerFactory
  def create_handler(action)
    case action.to_sym
    when :create_layer then OpenLayerCreator.new(Geoserver.new)
    when :destroy_layer then OpenLayerDestroyer.new(Geoserver.new)
    end
  end
end