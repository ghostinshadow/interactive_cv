class PdfDocumentGenerator
  attr_reader :filename, :document_name, :extension, :feedback

  def initialize(options = {})
    @generated_document =  TemporaryDocument.new({extension: '.pdf', encoding_option: 'w:ASCII-8BIT'})
    @temp_document = TemporaryDocument.new({extension: '.pdf', encoding_option: "w:ASCII-8BIT"})
    @feedback = options.fetch(:feedback)
    @locals = {feedback: @feedback}
  end

  def render_pdf_based_on_feedback
  	pdf_string = renderer.render(template: 'documents/_feedback_template.html.haml',
                                 locals: locals, layout: false, encoding: "UTF-8",
                                 margin: { top: 30 }, pdf: 'feedback')
    temp_document.data = pdf_string
    temp_document.create_tempfile_from_content
  end


  def generate_document
  	generated_pdf = render_pdf_based_on_feedback
  	generated_document.data = combine_generated_pdf_with_static(generated_pdf)
  	generated_document
  end

  private

  def combine_generated_pdf_with_static(generated_pdf)
  	pdf = CombinePDF.new
    pdf << CombinePDF.load(generated_pdf.path)
    pdf << CombinePDF.load("#{Rails.root.to_s}/public/OleksandrKychunProfile.pdf")
  	pdf.to_pdf
  end

  def locals
  	@locals
  end

  def temp_document
  	@temp_document
  end

  def generated_document
  	@generated_document
  end

  def renderer
    @renderer ||= ApplicationController
  end
end
