require 'rest_client'

module RestClient
	def self.get_json(*args)
		require 'json' unless defined? JSON
		data = get(*args)
		data && JSON.parse(data, :symbolize_names => true)
	end
end

class Reddit
	def user_agent
		user_agent = 'reddit-data/1.0 (/r/njr123 @reednj)'
	end

	def latest_comments(subreddit='all')
		data_url = "https://www.reddit.com/r/#{subreddit}/comments.json?raw_json=1&limit=100"
		data = RestClient.get_json data_url, :user_agent => user_agent
		return data[:data][:children].map {|c| c[:data] } 
	end

	def info(ids, options = {})
		ids = [ids] if ids.is_a? String
		options[:user_agent] ||= self.user_agent

		s = RestClient.get('https://api.reddit.com/api/info', {
			:user_agent => options[:user_agent],
			:params => { :id => ids.join(','), :raw_json => 1 }
		})

		data = JSON.parse s, :symbolize_names => true
		result = data[:data][:children].map {|t| t[:data] }
		return result
	end
end
