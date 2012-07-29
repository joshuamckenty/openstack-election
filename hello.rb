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
  property :confirmed, Boolean, :default  => false
end

DataMapper.finalize
Post.auto_upgrade!
Nomination.auto_upgrade!

# get '/' do
#   @posts = Post.all(:order => [:id.desc], :limit => 20)
#   erb :index
# end

helpers do
  
  def getGravatarURL(email)
    return "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest(email.strip.downcase)}"
  end
  
end

get '/' do
  @nominations = repository(:default).adapter.select('select candidate, email, confirmed, count(nominator_email) as nomcount from nominations group by email')
  # @nominations = Nomination.aggregate(:candidate, :email, :all.count)
  # @nominations = Nomination.all(:order => [:candidate.desc], :limit => 100)
  erb :index
end

get '/nomination/new' do
  erb :new
end

get '/nomination/:email' do
  @nom = Nomination.first(:email => params[:email])
  erb :nomination
end

post '/nomination/create' do
  nom = Nomination.new(:candidate => params[:candidate], :nominator_email => params[:nominator_email], :email => params[:email])
  if nom.save
    status 201
    redirect "/nomination/#{nom.email}"
  else
    status 412
    redirect '/'
  end
end