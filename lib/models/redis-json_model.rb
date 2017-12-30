require 'redis'
require 'json'

class RedisModel
	def self.redis
		Redis.current
	end

	def redis
		self.class.redis
	end
end

class RedisJSONModel < RedisModel
    def initialize(data = nil)
        @values = data || {}
    end

    def save(key)
        self.redis.set key, (self.values||{}).to_json
    end

    def self.load_data(key)
        JSON.parse self.redis.get(key)||'{}', :symbolize_names => true
    end

    def self.load(key)
        return self.new load_data(key)
    end

    def values
        @values
    end

    def [](field_name)
        @values[field_name.to_sym]
    end

    def []=(field_name, v)
        @values[field_name.to_sym] = v
    end

end
