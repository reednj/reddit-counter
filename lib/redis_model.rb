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

class RedisTimeSeries < RedisModel
	attr_accessor :value
    attr_accessor :created_date
    attr_accessor :redis_key

	def initialize(value, created_date)
		self.value = value.to_f
		self.created_date = created_date
	end

	def self.get_by_index(redis_key, n)
        data = self.redis.zrevrange redis_key, n, n+1, :with_scores => true
        return nil unless data && !data.empty?

        record = data.first
        t = self.new(record.first, Time.at(record.last))
        t.redis_key = redis_key
        return t
    end

    def self.current_rate(redis_key)
        record_1 = self.get_by_index redis_key, 0
        record_2 = self.get_by_index redis_key, 1
        (record_1.value - record_2.value) / (record_1.created_date - record_2.created_date)
    end
    
    def save(redis_key=nil)
        k = redis_key || self.redis_key || raise('redis_key required')
        self.redis.zadd k, created_date.to_f, value.to_f
        return self
    end

    def to_s
        "[#{redis_key}:#{created_date}]:#{value}"
    end
end


