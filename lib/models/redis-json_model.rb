require 'redis'
require 'json'

REDIS = Redis.new

class RedisJSONModel
    def initialize(data = nil)
        @values = data || {}
    end

    def redis
        self.class.redis
    end

    def self.redis
        REDIS
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

    def empty?
        self.values.keys.empty?
    end
end
