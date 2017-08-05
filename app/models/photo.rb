require 'exifr/jpeg'

class Photo

	attr_accessor :id, :location

	attr_writer :contents

	def self.mongo_client
		@@db = Mongoid::Clients.default
	end

	def initialize (hash=nil)
		if !hash.nil?
			if !hash[:_id].nil?
				@id=hash[:_id].to_s
			end
			@location = hash[:metadata].nil? ? nil : Point.new(hash[:metadata][:location])
		end
	end

	def persisted?
		return @id.nil? ? false : true
	end

	def save
		if !self.persisted?
			gps = EXIFR::JPEG.new(@contents).gps
			@location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
			@contents.rewind
			description = {}
			description[:content_type] = "image/jepg"
			description[:metadata]={:file=>@location.to_hash[:type],:location=>@location.to_hash[:coordinates]}
			grid_file = Mongo::Grid::File.new(@contents.read, description)
			id = Photo.mongo_client.database.fs.insert_one(grid_file)
			@id = id.to_s

		end
	end
end