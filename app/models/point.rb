class Point

## test
	attr_accessor :longitude, :latitude

	def initialize params
		if (params[:type])
			@longitude = params[:coordinates][0]
			@latitude = params[:coordinates][1]
		else
			@longitude = params[:lng]
			@latitude = params[:lat]
		end
		
	end

	def to_hash
		hash = {}
		hash[:type]="Point"
		hash[:coordinates]=[]
		hash[:coordinates][0]=@longitude
		hash[:coordinates][1]=@latitude
		return hash
	end

end