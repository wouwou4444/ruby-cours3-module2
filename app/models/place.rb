class Place

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


