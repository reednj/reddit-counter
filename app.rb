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
set :version, 'v0.1'

configure :development do
	Dir['./lib/*.rb'].each { |f| also_reload f }
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
	threads = RedditCounter.new 'reddit:threads'

	data = {
		:comments => {
			:age => comments.count.created_date.age,
			:count => comments.count.value,
			:rate => comments.rate.value
		},
		:threads => {
			:age => threads.count.created_date.age,
			:count => threads.count.value,
			:rate => threads.rate.value
		}
	}

	erb :home, :locals => {
		:_js => data
	}
end



