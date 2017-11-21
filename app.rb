require 'sinatra'
require 'sinatra/cookies'
require 'sinatra/content_for'
require 'sinatra/json'

require 'json'
require 'erubis'

require "sinatra/reloader" if development?

require './lib/model'
require './lib/extensions'

use Rack::Deflater
set :erb, :escape_html => true
set :version, `git describe --long`.to_s.strip
set :simple_version, settings.version.to_s.split('-')[0..1].join('.')

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
	milestone = comments.time_until(30e9)
	milestone = Time.now + milestone
	milestone = milestone.strftime('%e %B %Y')

	erb :home, :locals => {
		:_js => { :comments => comments.to_h },
		:comments => comments,
		:milestone => milestone
	}
end

get '/top' do
	erb :top, :locals => {
		:threads => RedditThreadRate.top_by_rate(10)
	}
end

get '/top.json' do
	json RedditThreadRate.top_by_rate(50).map {|t| t.values }
end

get '/data/comments.json' do
	comments = RedditCounter.new 'reddit:comments'
	json comments.to_h
end
