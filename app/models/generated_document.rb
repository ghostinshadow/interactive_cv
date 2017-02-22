class GeneratedDocument < ApplicationRecord
	mount_uploader :pdf, PdfUploader

	validates_presence_of :feedback, :pdf
end
