require 'redis'
require 'digest/sha1'

helpers do
    def cache(options={}, &block)
        k = (request.url + options[:key].to_s).sha1
		Redis.current.cache("sinatra:cache:#{k}", options, &block)
	end
end


class Redis
	def cache(key, options={})
        options ||= {}
        options[:for] ||= 60.0

        data = self.get(key) || begin
            data = yield().to_s
            self.set key, data
            self.expire key, options[:for].to_i
            data
        end
    end
end

class String
    def sha1
        Digest::SHA1.hexdigest self
    end
end
