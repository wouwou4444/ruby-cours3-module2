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
end