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
		return key
	end

	def refresh key
		if @keys[key] == nil
			return false
		elsif Time.now.to_i - @keys[key][:keep_alive_stamp] < @ttl
			@keys[key][:keep_alive_stamp] = Time.now.to_i
			return true
		else
			#key has expired already. delete it and move on
			delete(key)
			return false
		end
	end

	def delete key
		if @keys[key] == nil
			return false
		end
		@keys.delete(key)
		@free.delete(key)
		return true
	end

	def release key
		if @keys[key] == nil || @keys[key][:assigned_stamp] == 0
			return false
		end
		@keys[key][:assigned_stamp] = 0
		@free[key] = 1
		return true
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