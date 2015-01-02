require 'sinatra'
require 'json'
require './key_server.rb'

set :port, 8080

key_server = KeyServer.new

Thread.new do 
  while true do
     sleep 1
     key_server.cleanup
  end
end

get '/' do
	'ok'
end

get '/keys' do
	keys = key_server.generate 10, 300
	content_type :json
	keys.to_json
end

get '/key' do 
	content_type :json
	res = key_server.get
	if res == nil
		404
	else
		res.to_json
	end
end

get '/key/release/:id' do |key|
	content_type :json
	key_server.release(key).to_json
end

get '/key/delete/:id' do |key|
	content_type :json
	key_server.delete(key).to_json
end

get '/key/refresh/:id' do |key|
	content_type :json
	key_server.refresh(key).to_json
end