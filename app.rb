require 'sinatra'
require './key_server.rb'

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
	key_server.generate 10, 300
	'ok'
end

get '/key' do 
	res = key_server.get
	if res == nil
		404
	else
		res
	end
end

get '/key/release/:id' do |key|
	key_server.release key
end

get '/key/delete/:id' do |key|
	key_server.delete key
end

get '/key/refresh/:id' do |key|
	key_server.refresh key
end