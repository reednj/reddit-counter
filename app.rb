require 'rest_client'
require 'yaml'

require './model'

class App
	def main
		update_counter
	end

	def update_counter
		comment_count = get_latest_id
		current_count = TagValue.for_tag('reddit-comment-count', comment_count).save

		unless current_count.prev.nil?
			comment_rate = comments_per_second(current_count, current_count.prev)
			current_rate = TagValue.for_tag('reddit-comment-rate', comment_rate).save
		end

		puts current_rate.value.round(2).to_s + " comments/sec"	
	end

	def comments_per_second(current, prev)
		return nil if current.nil? || prev.nil?

		delta_v = current.value - prev.value
		delta_t = current.created_date - prev.created_date
		delta_v.to_f / delta_t.to_f 
	end

	def get_latest_id
		get_latest.first[:id].to_i 36
	end

	def get_latest
		user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6)'
		text_data = RestClient.get "http://www.reddit.com/comments.json?limit=2&sort=new", :user_agent => user_agent
		data = JSON.parse text_data, :symbolize_names => true
		return data[:data][:children].map { |c| c[:data]  }
	end
end

class Time
	def age
		Time.now - self
	end
end

App.new.main