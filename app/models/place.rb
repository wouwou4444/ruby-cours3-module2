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

end 


