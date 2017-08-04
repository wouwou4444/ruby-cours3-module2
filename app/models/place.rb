class Place

	attr_accessor :id, :formatted_address, :location, :address_components

	def initialize params
		@id = params[:_id].to_s
		@address_components = []
		if !params[:address_components].nil?
			params[:address_components].each { |ac| @address_components << AddressComponent.new(ac)}
		end
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
		doc = self.collection.find(:_id => BSON::ObjectId.from_string(id)).first
		doc.nil? ? nil : self.new(doc)
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

	def self.get_address_components (sort ={}, offset=0,limit="unlimited")
		#col = []
		if (sort.empty?)
			if (limit != "unlimited")
				self.collection.aggregate([
				{:$project =>{:_id=>1, :address_components =>1, :formatted_address=> 1, "geometry.geolocation" => 1} }, 
				{:$unwind=>"$address_components"},
				{:$skip => offset}, 
				:$limit => limit])
			else
				self.collection.aggregate([
				{:$project =>{:_id=>1, :address_components =>1, :formatted_address=> 1, "geometry.geolocation" => 1} }, 
				{:$unwind=>"$address_components"},
				{:$skip => offset}])
			end
		else
			if (limit != "unlimited")
				self.collection.aggregate([
				{:$project =>{:_id=>1, :address_components =>1, :formatted_address=> 1, "geometry.geolocation" => 1} }, 
				{:$unwind=>"$address_components"}, 
				{:$sort=> sort}, 
				{:$skip => offset}, 
				:$limit => limit])
			else
				self.collection.aggregate([
				{:$project =>{:_id=>1, :address_components =>1, :formatted_address=> 1, "geometry.geolocation" => 1} }, 
				{:$unwind=>"$address_components"}, 
				{:$sort=> sort}, 
				{:$skip => offset}])
			end

		end
	end

	def self.get_country_names
				self.collection.aggregate([
				{:$project =>{:_id=>1, :address_components =>1 } }, 
				{:$unwind=>"$address_components"},
				{:$project=>{"address_components.long_name"=>1,"address_components.types"=>1}},
				{:$unwind=>"$address_components.types"},
				{:$match=>{"address_components.types"=>"country"}},
				{:$group=>{:_id=> "$address_components.long_name",:name=>{:$addToSet=>"$address_components.long_name"} }}
				])
				.to_a.map {|h| h[:_id]}
	end

	def self.find_ids_by_country_code country_code
				self.collection.aggregate([
				{:$project =>{:_id=>1, :address_components =>1 } }, 
				{:$unwind=>"$address_components"},
				{:$project=>{"address_components.short_name"=>1,"address_components.types"=>1}},
				{:$unwind=>"$address_components.types"},
				{:$match=>{"address_components.types"=>"country"}},
				{:$match=>{"address_components.short_name"=>country_code}},
				])
				.map {|doc| doc[:_id].to_s}
	end

	def self.create_indexes
		self.collection.indexes.create_one({"geometry.geolocation"=>Mongo::Index::GEO2DSPHERE})
	end

	def self.remove_indexes
		indexes = self.collection.indexes.map {|r| r[:name]}
		indexes.each { |index_name |
			if index_name["2dsphere"] 
				self.collection.indexes.drop_one(index_name)
			end
		}
	end

	def self.near (point, max_meters="unlimited")
		if max_meters == "unlimited"
			self.collection.find("geometry.geolocation"=>
			{:$near=>
				{
					:$geometry=>point.to_hash
				}
			})
		else
			self.collection.find("geometry.geolocation"=>
			{:$near=>
				{
					:$geometry=>point.to_hash,
					:$maxDistance=>max_meters
				}
			})
		end
	end

	def near (max_meters="unlimited")
		if max_meters == "unlimited"
			Place.to_places(Place.near(@location))
		else
			Place.to_places(Place.near(@location, max_meters))
		end
	end
end 


