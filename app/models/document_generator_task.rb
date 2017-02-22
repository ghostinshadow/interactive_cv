class DocumentGeneratorTask

  @queue = :documents

  def self.perform(method, args = {})
    args = args.with_indifferent_access
    Resque.logger.info("Perform document generation:" + method.to_s)
    document_generator = DocumentGeneratorFactory.specific_generator(key: method, args: args)
    document = document_generator.generate_document
    tempfile = document.create_tempfile_from_content

    GeneratedDocument.create(feedback: args[:feedback], pdf: tempfile)
  end

end