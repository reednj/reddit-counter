require 'rest_client'
require './lib/model'

class App
	def main
		update_comment_rate
		update_thread_rate
	end

	def update_comment_rate
		comment_count = get_latest_comment_id
		current_count = TagValue.for_tag('reddit-comment-count', comment_count).save

		unless current_count.prev.nil?
			comment_rate = calculate_rate(current_count, current_count.prev)
			current_rate = TagValue.for_tag('reddit-comment-rate', comment_rate).save
			puts current_rate.value.round(2).to_s + " comments/sec"
		end		
	end

	def update_thread_rate
		thread_count = get_latest_thread_id
		current_count = TagValue.for_tag('reddit-thread-count', thread_count).save

		unless current_count.prev.nil?
			comment_rate = calculate_rate(current_count, current_count.prev)
			current_rate = TagValue.for_tag('reddit-thread-rate', comment_rate).save
			puts current_rate.value.round(2).to_s + " threads/sec"
		end
	end

	def calculate_rate(current, prev)
		return nil if current.nil? || prev.nil?

		delta_v = current.value - prev.value
		delta_t = current.created_date - prev.created_date
		delta_v.to_f / delta_t.to_f 
	end

	def get_latest_thread_id
		get_reddit_listing('new.json?limit=2&sort=new').first[:id].to_i 36
	end

	def get_latest_comment_id
		get_latest_comment.first[:id].to_i 36
	end

	def get_latest_comment
		get_reddit_listing 'comments.json?limit=2&sort=new'
	end

	def get_reddit_listing(path)
		user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6)'
		text_data = RestClient.get "http://www.reddit.com/#{path}", :user_agent => user_agent
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