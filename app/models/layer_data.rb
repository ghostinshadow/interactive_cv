class LayerData
  attr_reader :storage_name, :ws, :layer_name, :db_name, :file_path
  attr_accessor :hostname

  def initialize(hsh = {})
    @ws = hsh.fetch(:ws)
    @layer_name = hsh.fetch(:layer_name)
    @db_name = hsh.fetch(:db_name)
    @file_path = hsh.fetch(:file_path)
    @storage_name = "#{@layer_name}_store"
    @hostname = nil
  end
end