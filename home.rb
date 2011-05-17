require 'sinatra'
require 'haml'
require 'curb'
require 'nokogiri'

enable :sessions

get '/' do
  haml :index
end

get '/login' do
  haml :login
end

get '/logout' do
  session[:user_name] = nil
  session[:login_name] = nil
  session[:password] = nil
  redirect '/'
end

post '/log-in' do
  c = Curl::Easy.new("https://#{params[:name]}:#{params[:password]}@www10.v1host.com/sandp/rest-1.v1/Data/Member?sel=Name&where=Username='#{params[:name]}'")
  c.perform
  if c.response_code == 401
    redirect '/unauthorized'
  else
    name = Nokogiri::XML(c.body_str).at_xpath('Assets/Asset/Attribute[@name="Name"]/text()').to_s
    session[:user_name] = name
    session[:login_name] = params[:name]
    session[:password] = params[:password]
    redirect '/success'
  end
end

get '/unauthorized' do
  haml :unauthorized
end

get '/success' do
  c = Curl::Easy.new("https://#{session[:login_name]}:#{session[:password]}@www10.v1host.com/sandp/rest-1.v1/Data/Story\?sel\=Name,Estimate,Number,Status.Name\&where\=%28Team.Name\=%27SAS%20EMEA%20Integration%20Team%27\;Timebox.Name\=%27Sprint%207%27%29")
  c.perform
  @data = []
  Nokogiri::XML(c.body_str).xpath('//Assets/Asset').each do |row|
    @data.push({:number => row.at_xpath('Attribute[@name="Number"]/text()').to_s,
    :status => row.at_xpath('Attribute[@name="Status.Name"]/text()').to_s,
    :name => row.at_xpath('Attribute[@name="Name"]/text()').to_s,
    :estimate => row.at_xpath('Attribute[@name="Estimate"]/text()').to_s})
  end
  puts @data
  haml :welcome
end
