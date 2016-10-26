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
	also_reload './lib/model.rb'
	also_reload './lib/extensions.rb'
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
	current_count = TagValue.latest_for_tag('reddit-comment-count')
	thread_count = TagValue.latest_for_tag('reddit-thread-count')

	data = {
		:comments => {
			:age => current_count.created_date.age,
			:count => current_count.value,
			:rate => TagValue.latest_for_tag('reddit-comment-rate').value
		},
		:threads => {
			:age => thread_count.created_date.age,
			:count => thread_count.value,
			:rate => TagValue.latest_for_tag('reddit-thread-rate').value
		}
	}

	erb :home, :layout => :_layout, :locals => {
		:_js => data
	}
end



