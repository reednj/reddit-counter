#!/usr/bin/env ruby
require 'time'
require 'rest_client'
require './lib/redis_model'
require './lib/extensions'

class App
	def main
		update_comment_data
		update_thread_data
    end
    
    def update_comment_data
        next_value = get_latest_comment_id
        current = RedisTimeValue.new 'reddit:comments:current_count'
        daily =  RedisTimeValue.new "reddit:comments:count:#{Date.today.to_key}"
        
        if current && current.data_string
            next_rate = current.calculate_rate next_value
            RedisTimeValue.set 'reddit:comments:current_rate', next_rate
        end

        current.set next_value
        daily.set next_value unless daily.exist?
    end

    def update_thread_data
        next_value = get_latest_thread_id
        current = RedisTimeValue.new 'reddit:threads:current_count'
        
        if current && current.data_string
            next_rate = current.calculate_rate next_value
            RedisTimeValue.set 'reddit:threads:current_rate', next_rate
        end

        current.set next_value
    end

	def get_latest_thread_id
        get_latest_threads.first[:id].to_i 36
	end

	def get_latest_comment_id
		get_latest_comments.first[:id].to_i 36
    end
    
    def get_latest_threads
        get_reddit_listing 'new.json?limit=2&sort=new'
    end

	def get_latest_comments
		get_reddit_listing '/r/all/comments.json?limit=2&sort=new'
	end

	def get_reddit_listing(path)
		user_agent = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_6)'
		text_data = RestClient.get "https://www.reddit.com/#{path}", :user_agent => user_agent
		data = JSON.parse text_data, :symbolize_names => true
		return data[:data][:children].map { |c| c[:data]  }
	end
end

App.new.main
