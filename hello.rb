# Sample Sinatra app with DataMapper
# Based on http://sinatra-book.gittr.com/ DataMapper example

# require 'sinatra'   # required for framework detection in cloud foundry.
require 'rubygems'
require 'bundler'
Bundler.require

if ENV['VCAP_SERVICES'].nil?
  DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/election.db")
else
  require 'json'
  svcs = JSON.parse ENV['VCAP_SERVICES']
  mysql = svcs.detect { |k,v| k =~ /^mysql/ }.last.first
  creds = mysql['credentials']
  user, pass, host, name = %w(user password host name).map { |key| creds[key] }
  DataMapper.setup(:default, "mysql://#{user}:#{pass}@#{host}/#{name}")
end

class Post
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :body, Text
  property :created_at, DateTime
end

class Nomination
  include DataMapper::Resource
  property :id, Serial
  property :candidate, String
  property :email, String
  property :nominator_email, String
  property :body, Text
  property :created_at, DateTime
  property :published, Boolean, :default  => false
end

DataMapper.finalize
Post.auto_upgrade!

get '/' do
  @posts = Post.all(:order => [:id.desc], :limit => 20)
  erb :index
end

get '/post/new' do
  erb :new
end

get '/post/:id' do
  @post = Post.get(params[:id])
  erb :post
end

post '/post/create' do
  post = Post.new(:title => params[:title], :body => params[:body])
  if post.save
    status 201
    redirect "/post/#{post.id}"
  else
    status 412
    redirect '/'
  end
end