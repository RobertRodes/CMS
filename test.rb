require 'sinatra'
require 'sinatra/reloader'

configure do
  enable :sessions
end

before do
  # session[:start] = 'start'
end

get '/' do
  session
end

get '/:value' do
  session[:test] = 'test'
  redirect '/'
end