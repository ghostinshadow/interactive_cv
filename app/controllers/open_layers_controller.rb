class OpenLayersController < ApplicationController
	before_action :set_layers, only: [:index, :create]

	def index		
		respond_to do |format|
			format.html
			format.json{ render json: @layers.to_json}
		end
	end

	def new
		@layer = OpenLayer.new(workspace_name: "imported_layers")
	end

	def create
		@layer = OpenLayer.create(open_layer_params)
		flash.now[:notice] = t('open_layers.pending_creation')
	end

	def destroy
		@destroyed = OpenLayer.find(params[:id]).destroy
		redirect_to open_layers_path
	end

	private

	def set_layers
		@layers = OpenLayer.to_json
	end

  def open_layer_params
  	params.require(:open_layer).permit(:name, :group_id, :workspace_name, :db_name, :description, :shapefile_archive)
  end
end