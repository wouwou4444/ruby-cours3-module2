class Photo

	attr_accessor :id, :location

	attr_writer :contents

	def self.mongo_client
		@@db = Mongoid::Clients.default
	end
end