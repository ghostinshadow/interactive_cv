class ShapefileImportPreparations
  attr_reader :file_path, :filename, :path_to_unzipped_data

  def initialize(hsh={})
    @file_path = hsh.fetch(:file_path)
  end


  def perform
    form_temp_path_and_filename
    return if already_extracted?
    create_temp_directory
    unzip_file
  end

  def path_to_shapefile
    Dir.glob("#{@path_to_unzipped_data}/*.shp").first
  end

  private

  def unzip_file
    Zip::File.open(@file_path) do |zip_file|
      zip_file.each do |entry|
        Resque.logger.info("Extracting #{entry.name}")
        zip_file.extract(entry, @path_to_unzipped_data + "/#{entry.name}")
      end
    end
  end

  def already_extracted?
    File.directory?(@path_to_unzipped_data)
  end

  def create_temp_directory
    FileUtils::mkdir @path_to_unzipped_data
  end

  def form_temp_path_and_filename
    splitted_path = @file_path.split('/')
    @filename = splitted_path.pop
    @path_to_unzipped_data = splitted_path.push('unzipped').join('/')
  end
end
