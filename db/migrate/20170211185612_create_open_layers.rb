class CreateOpenLayers < ActiveRecord::Migration[5.0]
  def change
    create_table :open_layers do |t|
      t.string :name
      t.string :workspace_name
      t.string :description
      t.string :shapefile_archive
      t.string :db_name
      t.boolean :exists

      t.timestamps
    end
  end
end
