class CreateGeneratedDocuments < ActiveRecord::Migration[5.0]
  def change
    create_table :generated_documents do |t|
      t.string :feedback
      t.text :pdf

      t.timestamps
    end
  end
end
