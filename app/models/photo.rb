require 'exifr/jpeg'

class Photo

	attr_accessor :id, :location

	attr_writer :contents

	#has_one :place

	def self.mongo_client
		@@db = Mongoid::Clients.default
	end

	def initialize (hash=nil)
		if !hash.nil?
			if !hash[:_id].nil?
				@id=hash[:_id].to_s
			end

			 if (!hash[:metadata].nil?)
				@location = ( hash[:metadata][:location].nil?) ? nil : Point.new(hash[:metadata][:location])
				@place = ( hash[:metadata][:place].nil?) ? nil : (hash[:metadata][:place])
			end
		end
	end

	def persisted?
		Rails.logger.debug {"persisted?: #{!@id.nil?}"}
		return @id.nil? ? false : true
	end

	def save
		if !self.persisted?
			Rails.logger.debug {"persisted?: #{!@id.nil?} not persisted"}
			gps = EXIFR::JPEG.new(@contents).gps
			@location = Point.new(:lng=>gps.longitude, :lat=>gps.latitude)
			@contents.rewind
			description = {}
			description[:content_type] = "image/jpeg"
			if @place.nil?
				description[:metadata]={:file=>@location.to_hash[:type],:location=>@location.to_hash}
			else
				description[:metadata]={:file=>@location.to_hash[:type],:location=>@location.to_hash, place=>@place}
			end
			grid_file = Mongo::Grid::File.new(@contents.read, description)
			id = Photo.mongo_client.database.fs.insert_one(grid_file)
			@id = id.to_s
		else
			Rails.logger.debug {"persisted?: #{!@id.nil?} persisted"}
			self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(@id)).update_one('$set'=>{"metadata.location"=>@location.to_hash,"metadata.place"=>@place})
		end
	end

	def self.all (skip=0, limit="unlimited")
		if limit == "unlimited"
			Photo.mongo_client.database.fs.find.skip(skip).map { |doc| Photo.new doc}
		else
			Photo.mongo_client.database.fs.find.skip(skip).limit(limit).map { |doc| Photo.new doc}
		end
	end

	def self.find id
		file = self.mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(id)).first
		if !file.nil? 
			return Photo.new file
		else
			return nil
		end
	end

	def contents
		Rails.logger.debug {"@id: #{ @id}"}
		file = Photo.mongo_client.database.fs.find_one(:_id=>BSON::ObjectId.from_string(@id))
		buffer = ""
		if !file.chunks.nil?
			file.chunks.reduce([]) { |x,chunk| buffer << chunk.data.data}
		end
		return buffer
	end

	def destroy
		self.class.mongo_client.database.fs.find(:_id=>BSON::ObjectId.from_string(@id)).delete_one
	end

	def find_nearest_place_id (max_distance)
		point = @location
		params = Place.near(point, max_distance).limit(1).projection(:_id=>1).first
		return params.nil? ? nil : params[:_id]
	end

	def place=(place)
		@place = place if place.is_a? BSON::ObjectId
		@place = BSON::ObjectId.from_string(place) if  place.is_a? String 
		@place = BSON::ObjectId(place.id) if place.is_a? Place
	end

	def place
		return @place.nil? ? nil : Place.find(@place.to_s)
	end

	def self.find_photos_for_place id
		result = self.mongo_client.database.fs.find("metadata.place"=>BSON::ObjectId(id)) if id.is_a? String
		result = self.mongo_client.database.fs.find("metadata.place"=>id) if id.is_a? BSON::ObjectId
		return result
	end
end