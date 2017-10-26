require 'json'
require 'redis'
require './lib/extensions'

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

    def exist?
        self.redis.exists redis_key
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

    # calculate the rate from the last few days / last week so that we can project out
    # what the count will be in the long term
    def long_term_rate
        @long_term_rate ||= begin
            previous_count = RedisTimeValue.new("#{key_base}:count:#{Date.yesterday.to_key}")
            (count.value - previous_count.value) / (count.created_date - previous_count.created_date)
        end
    end

    # the count provided might be some time in the past, so we want to
    # calculate it forward based on the age and the rate and get an
    # estimate of what the current value would be. The client does this
    # also in js, but we need it on the server sometimes too
    def estimated_count
        count.value + rate.value * count.created_date.age
    end

    def time_until(n)
        delta = (n - estimated_count)
        t = delta / rate.value
        t <= 1.day ? t : delta / long_term_rate
    end

    def to_h
        {
            :created_date => count.created_date,
            :age => count.created_date.count,
            :count => count.value,
            :rate => rate.value
        }
    end
end

