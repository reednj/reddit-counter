require 'rest_client'
require 'json'

class Reddit
	def latest_comments(subreddit='all')
		user_agent = 'reddit-data/1.0 (/r/njr123 @reednj)'
		data_url = "https://www.reddit.com/r/#{subreddit}/comments.json?raw_json=1&limit=100"
		raw = RestClient.get data_url, :user_agent => user_agent
		data = JSON.parse raw, :symbolize_names => true
		return data[:data][:children].map {|c| c[:data] } 
	end
end
