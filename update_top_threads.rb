#!/usr/bin/env ruby

require 'yaml'
require_relative './lib/reddit'
require_relative './lib/model'

Reddit.new.latest_comments.each do |c|
    t = RedditThreadRate.load c[:link_id]
    t.update_count c[:num_comments]
    t[:title] = c[:link_title]
    t[:subreddit] = c[:subreddit]
    t.save
end

RedditThreadRate.top_by_rate(50).each do |t|
    puts "#{t[:rate].round(1)}/hr : [/r/#{t[:subreddit]}] #{t[:title].to_s.truncate 90}"
end
