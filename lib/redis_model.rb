require 'json'
require 'redis'

REDIS = Redis.new

class RedisModel
	def self.redis
		REDIS
	end

	def redis
		self.class.redis
	end
end

class RedisTimeValue < RedisModel
    attr_accessor :redis_key

    def self.calculate_rate(redis_key, next_value)
        current = self.new(redis_key)
        (next_value - current.value) / (Time.now - current.created_date)
    end

    def self.set(redis_key, value)
        self.redis.set redis_key, "#{Time.now.to_f}:#{value.to_f}"
    end

    def initialize(redis_key)
        self.redis_key = redis_key
    end
    
    def data_string
        @data_string ||= self.redis.get redis_key
    end

    def data_items
        @data_items ||= data_string.split(':') || []
    end

    def created_date
        @created_date ||= Time.at(data_items[0].to_f)
    end

    def value
        @value ||= data_items.last.to_f
    end

    def set(next_value)
        self.class.set redis_key, next_value
        return self.class.new self.redis_key
    end

    def calculate_rate(next_value)
        self.class.calculate_rate redis_key, next_value
    end
end

class RedditCounter < RedisModel
    attr_accessor :key_base

    def initialize(key_base)
        self.key_base = key_base
    end

    def count
        @current_count ||= RedisTimeValue.new "#{key_base}:current_count"
    end

    def rate
        @current_rate ||= RedisTimeValue.new "#{key_base}:current_rate"
    end

    def to_h
        raise 'not_implemented'
    end
end

