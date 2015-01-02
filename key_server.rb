class KeyServer
	attr_reader :keys
	attr_reader :free
	attr_reader :ttl
  attr_reader :timeout

  def initialize
    @keys = { }
    @free = { }
  end

  #Generates the keys and returns them as an array.
  #ttl is the expiry time after which the keys get deleted
  #key_timeout is the time after which assigned keys get released
  def generate length, ttl, key_timeout
    @ttl = ttl
    @timeout = key_timeout

    while @free.length < length do
      #generates an 8 character random string
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

  #Returns a free key as string. Returns nil if no key is available
  def get
    key = nil

    while @free.length > 0 && key == nil
      keyObj = @free.shift
      key = keyObj[0]

      if Time.now.to_i - @keys[key][:keep_alive_stamp] < @ttl
        @keys[key][:assigned_stamp] = Time.now.to_i
        break

      else
        delete key
        key = nil

      end

    end
    return key

  end

  #Updates the ttl of the key. 
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

  #Deletes the key from the keystore. 
  def delete key

    if @keys[key] == nil
      return false
    end
    @keys.delete key
    @free.delete key
    return true

  end

  #Releases an assigned key
  def release key

    if @keys[key] == nil || @keys[key][:assigned_stamp] == 0
      return false
    end
    @keys[key][:assigned_stamp] = 0
    @free[key] = 1
    return true

 end

  #Cleanup task which goes through all the keys and releases/deletes them
  def cleanup 

    @keys.each do |key, val|
      if Time.now.to_i - @keys[key][:keep_alive_stamp] >= @ttl
        delete key
      elsif Time.now.to_i - @keys[key][:assigned_stamp] >= @timeout
        release key
      end
    end

  end

end
