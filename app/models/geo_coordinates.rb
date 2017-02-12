class GeoCoordinates
	attr_reader :latitude, :longitude

	def initialize(hsh = {})
		@latitude = hsh.fetch(:latitude, 24.0)
		@longitude = hsh.fetch(:longitude, 49.8)
	end

	def to_a
		[latitude, longitude]
	end
end