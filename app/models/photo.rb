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

			 if (!hash[:metadata].nil?)
				@location = ( hash[:metadata][:location].nil?) ? nil : Point.new(hash[:metadata][:location])
			end
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
			description[:content_type] = "image/jpeg"
			description[:metadata]={:file=>@location.to_hash[:type],:location=>@location.to_hash}
			grid_file = Mongo::Grid::File.new(@contents.read, description)
			id = Photo.mongo_client.database.fs.insert_one(grid_file)
			@id = id.to_s

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
			hash = {}
			hash[:_id] = file[:_id]
			if (!file[:metadata].nil?)
				if (!file[:metadata][:location.nil?])
					hash[:metadata]={:location=>file[:metadata][:location]}
				end
			end
			return Photo.new hash
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

	def find_nearest_place_id (max_meters="unlimited")
		point = @location
		Place.near (point, max_meters)
	end
end