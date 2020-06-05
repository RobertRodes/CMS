require 'sinatra'
require 'sinatra/reloader' if development?
require 'redcarpet'
require 'yaml'
require 'bcrypt'

configure do
  enable :sessions
  set :session_secret, 'fine thanks, and you?'
end

helpers do
  def markdown(text)
    md = Redcarpet::Markdown.new(Redcarpet::Render::HTML, tables: true)
    md.render(text)
  end
end

before do
  @files = Dir.children("#{data_path}").delete_if do |file| 
    file =~ /^\..+/ || File.directory?(file)
  end.sort
end

def data_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../data/test', __FILE__)
  else
    File.expand_path('../data', __FILE__)
  end
end

def root_path
  if ENV['RACK_ENV'] == 'test'
    File.expand_path('../test', __FILE__)
  else
    File.expand_path('..', __FILE__)
  end
end

def load_file(path)
  text = File.read(path)
  case File.extname(path)
  when '.md'
    markdown(text)
  when '.txt'
    headers["Content-Type"] = "text/plain"
    text
  else text
  end
end

def signed_in?
  session.key?(:username)
end

def validate_user
  unless signed_in?
    session[:message] = 'You must be signed in to do that.'
    redirect '/'
  end
end

def valid_user?(user, password)
  users = YAML.load_file(File.join(root_path, 'users.yml'))

  return false unless users.key?(user)

  password_hash = BCrypt::Password.new(users[user])
  users.key?(user) && password_hash == password
end

get '/' do
  @username = session[:username]
  erb :index
end

get '/users/signin' do
  erb :signin
end

post '/users/signin' do
  if valid_user?(params[:username].downcase, params[:password])
    session[:message] = 'Welcome!'
    session[:username] = params[:username]
    redirect '/'
  else
    status 422
    session[:message] = 'Invalid credentials.'
    erb :signin
  end
end

post '/users/signout' do
  session[:message] = "User '#{session[:username]}' signed out."
  session[:username] = nil
  redirect '/'
end

get '/new' do
  validate_user
  erb :new
end

post '/create' do
  redirect '/' if params[:cancel]
  validate_user

  name = params[:file_name]

  if name.empty?
    session[:message] = "Please enter a file name or cancel."
    status 422
    erb :new
  elsif @files.include?(name)
    session[:message] = "File '#{name}'' already exists; new file not created."
    redirect '/'
  else
    File.write(File.join(data_path, name), '')
    session[:message] = "New file '#{name}' created."
    redirect '/'
  end
end

get '/:file_name' do
  name = params[:file_name]
  unless @files.include?(name)
    session[:message] = "File '#{name}' not found."
    redirect '/'
  end
  load_file(File.join(data_path, name))
end

get '/:file_name/edit' do
  validate_user

  @name = params[:file_name]

  if !@files.include?(@name)
    session[:message] = "File '#{@name}' not found."
    redirect '/'
  end

  @file = File.read(File.join(data_path, @name))
  erb :edit
end

post '/:file_name/edit' do
  redirect '/' if params[:cancel]
  validate_user

  File.write(File.join(data_path, params[:file_name]), params[:text]) 
  session[:message] = "Changes to '#{params[:file_name]}' saved."
  redirect '/'
end

post '/:file_name/delete' do
  validate_user

  File.delete(File.join(data_path, params[:file_name]))
  session[:message] = "File '#{params[:file_name]}' deleted."
  redirect '/'
end

