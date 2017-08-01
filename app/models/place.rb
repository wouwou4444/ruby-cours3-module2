class Place

	attr_accessor :id, :formatted_address, :location, :address_components

	def initialize params
		@id = params[:_id].to_s
		@address_components = []
		params[:address_components].each { |ac| @address_components << AddressComponent.new(ac)}
		@location = Point.new(params[:geometry][:geolocation])
		@formatted_address = params[:formatted_address]

	end

    def self.mongo_client
        @@db = Mongoid::Clients.default 
    end

    def self.collection
        @@col = self.mongo_client[:places]
    end

	def self.load_all file
		hash= JSON.parse(file.read)
		self.collection.insert_many(hash)
	end

	def self.find_by_short_name s_name
		self.collection.find().aggregate([
		{:$match => {"address_components.short_name"=> {:$regex => s_name} }}
		])
		self.collection.find(
		{"address_components.short_name"=> {:$regex => s_name} }
		)
	end

	def self.to_places places
		col = []
		places.each { |p| col << Place.new(p)}
		return col
	end

	def self.find id
		self.new(self.collection.find(:_id => BSON::ObjectId.from_string(id)).first)
	end

	def self.all (offset=0, limit="unlimited")
		if (limit == "unlimited")
			self.to_places(self.collection.find.skip(offset))
		else
			self.to_places(self.collection.find.skip(offset).limit(limit))
		end
	end

	def destroy
		Place.collection.find(:_id=>BSON::ObjectId.from_string(@id)).delete_one
	end
end 


