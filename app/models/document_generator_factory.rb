class DocumentGeneratorFactory

	def self.specific_generator(key: method, args: )
    case key.to_sym
    when :generate_pdf then PdfDocumentGenerator.new(args)
    end
	end
end