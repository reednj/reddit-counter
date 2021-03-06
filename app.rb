require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/content_for'
require 'sinatra/json'

require 'json'
require 'erubis'

require "sinatra/reloader" if development?

require './lib/model'
require './lib/extensions'
require './lib/reddit'
require './lib/sinatra-redis_cache'

use Rack::Deflater
set :erb, :escape_html => true
set :version, `git describe --long`.to_s.strip
set :simple_version, settings.version.to_s.split('-')[0..1].join('.')
set :current_milestone, 31e9

configure :development do
	Dir['./lib/*.rb'].each { |f| also_reload f }
	Dir['./lib/**/*.rb'].each { |f| also_reload f }

	set :server, :thin
	set :port, 4567
end

configure :production do

end

helpers do

	# basically the same as a regular halt, but it sends the message to the 
	# client with the content type 'text/plain'. This is important, because
	# the client error handlers look for that, and will display the message
	# if it is text/plain and short enough
	def halt_with_text(code, message = nil)
		message = message.to_s if !message.nil?
		halt code, {'Content-Type' => 'text/plain'}, message
	end

end

get '/' do
	comments = RedditCounter.new 'reddit:comments'
	until_milestone =  comments.time_until(settings.current_milestone)
	milestone_time = (Time.now + until_milestone).utc
	milestone = milestone_time.strftime('%e %B %Y')
	milestone += " #{milestone_time.strftime('%H:%M')} UTC" if until_milestone < 7.days

	erb :home, :layout => :_layout, :locals => {
		:_js => { :comments => comments.to_h },
		:comments => comments,
		:milestone => milestone,
		:milestone_time => milestone_time
	}
end

get '/top' do
	erb :top, :layout => :_layout, :locals => {
		:threads => RedditThreadRate.top_by_rate(10)
	}
end

get '/data/top.html' do
	cache :for => 30 do
		n = params[:n].to_i
		n = 10 if n <= 0 || n > 100
		threads = RedditThreadRate.top_by_rate(n)
		erb :_top_threads, :locals => { :threads => threads }
	end
end

get '/data/top.json' do
	content_type :json
	cache :for => 30 do 
		RedditThreadRate.top_by_rate(50).map {|t| t.values }.to_json
	end
end

get '/data/comments.json' do
	comments = RedditCounter.new 'reddit:comments'
	json comments.to_h
end
