class OpenLayerDestroyer < OpenLayerHandler

  def initialize(geoserver)
    super
  end

  def process(hsh = {})
    layer_data = LayerData.new(hsh)
    destroy_open_layer(layer_data)
  end


  def destroy_open_layer(layer_data)
    destroy_layer(ws: layer_data.ws, layer_name: layer_data.layer_name)
    destroy_db_table(db_name: layer_data.db_name, table_name: layer_data.layer_name)
    destroy_data_store(ws: layer_data.ws, storage_name: layer_data.storage_name)
  end

  def destroy_db_table(db_name: , table_name: )
    binding.pry
    if geoserver.data_exist_in_db? db_name: db_name, table_name: table_name
     command_out = perform_postgres_query(database: db_name){|conn|
       conn.exec("drop table #{conn.quote_ident(table_name)}")
     }
     write_to_logfile(command_out.values)
    end
  end

  def destroy_layer( ws: , layer_name:)
    response = geoserver.delete_resource(url: "#{hostname}/geoserver/api/layers/#{ws}/#{layer_name}")
    write_to_logfile(response)
  end

  def destroy_data_store( ws: , storage_name:)
    response = geoserver.delete_resource(url: "#{hostname}/geoserver/api/stores/#{ws}/#{storage_name}")
    write_to_logfile(response)
  end

end

# l = OpenLayer.last.to_layer_data
# h = JSON.parse l.to_json
# h = h.with_indifferent_access
# o = OpenLayerDestroyer.new(Geoserver.new)
# o.process h