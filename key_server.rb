class KeyServer
	attr_reader :keys
	attr_reader :free
	attr_reader :ttl

	def initialize 
		@keys = { }
		@free = { }
	end

	def generate length, ttl
		@ttl = ttl
		while @free.length < length do
			key = (0...8).map { (65 + rand(26)).chr }.join
			if @keys[key] != nil
				next #this key code is already in use. Try another
			end
			@keys[key] = {
				keep_alive_stamp: Time.now.to_i,
				assigned_stamp: 0
			}
			@free[key] = 1
		end
		return @keys.keys
	end

	def get
		key = nil
		while @free.length > 0 && key == nil
			keyObj = @free.shift
			key = keyObj[0]
			if Time.now.to_i - @keys[key][:keep_alive_stamp] < @ttl
				@keys[key][:assigned_stamp] = Time.now.to_i
				break
			else
				delete(key)
				key = nil
			end
		end
		key
	end

	def refresh key
		if Time.now.to_i - @keys[key][:keep_alive_stamp] < @ttl
			@keys[key][:keep_alive_stamp] = Time.now.to_i
		else
			#key has expired already. delete it and move on
			delete(key)
		end
	end

	def delete key
		@keys.delete(key)
		@free.delete(key)
	end

	def release key
		@keys[key][:assigned_stamp] = 0
		@free[key] = 1
	end

	def cleanup 
		@keys.each do |key, val|
			if Time.now.to_i - @keys[key][:keep_alive_stamp] >= @ttl
				delete(key)
			end
			if Time.now.to_i - @keys[key][:assigned_stamp] >= 30
				release(key)
			end
		end
	end
end

if __FILE__ == $0
	test = KeyServer.new
	test.generate
	#puts test.keys
	puts test.get_free
	puts test.get_free
	puts test.get_free

	test.keys.each do |key, hash|
		puts hash[:keep_alive_stamp]
	end
end