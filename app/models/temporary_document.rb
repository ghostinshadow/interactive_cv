class TemporaryDocument
	attr_writer :data
	attr_reader :name

	def initialize(opts = {})
		@filename = opts.fetch(:filename, "DefaultDocument")
		@name = opts.fetch(:name, 'Document')
		@extension = opts.fetch(:extension, '.xlsx')
		@encoding_option = opts.fetch(:encoding_option, nil)
		@data = nil
	end

  def create_tempfile_from_content
	  temp_file = Tempfile.new([@filename, @extension])
    File.open(temp_file.path, @encoding_option || 'w'){|f|
      f.write(@data)
    }
    temp_file
  end
end