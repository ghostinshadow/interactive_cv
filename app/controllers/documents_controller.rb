class DocumentsController < ApplicationController
  def index
    @documents = GeneratedDocument.paginate(page: params[:page])
  end

  def new
  	@document = GeneratedDocument.new
  end

  def create
    task_uniqueness_validator = DocumentEnqueueValidator.new(document_params)
    if task_uniqueness_validator.task_valid_to_enqueue?
      Resque.enqueue(DocumentGenerator, :generate_pdf, document_params)
      flash.now[:notice] = "Will be generated soon"
    else
      flash.now[:notice] = "Unable to enqueue"
    end
  end

  private

  def document_params
    params.require(:document).permit(:feedback)
  end
end
