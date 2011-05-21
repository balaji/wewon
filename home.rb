require 'sinatra'
require 'haml'
require 'curb'
require 'nokogiri'
require 'json'

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
  session[:data] = nil
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
    redirect '/snapshot'
  end
end

get '/unauthorized' do
  haml :unauthorized
end

get '/snapshot' do
  unless not session[:data].nil?
    s = 'Sprint 7'
    c = Curl::Easy.new("https://#{session[:login_name]}:#{session[:password]}@www10.v1host.com/sandp/rest-1.v1/Data/Story\?sel\=Name,Estimate,Number,Status.Name\&where\=%28Team.Name\=%27SAS%20EMEA%20Integration%20Team%27\;Timebox.Name\=%27" + s + "%27%29")
    c.perform
    @data = []
    Nokogiri::XML(c.body_str).xpath('//Assets/Asset').each do |row|
      @data.push({
        :number => row.at_xpath('Attribute[@name="Number"]/text()').to_s,
        :status => row.at_xpath('Attribute[@name="Status.Name"]/text()').to_s,
        :name => row.at_xpath('Attribute[@name="Name"]/text()').to_s,
        :estimate => ((row.at_xpath('Attribute[@name="Estimate"]/text()').to_s == "")? "-" : row.at_xpath('Attribute[@name="Estimate"]/text()').to_s),
        :story_id => row.at_xpath("@id").to_s.split(':').last
      })
    end
    session[:data] = @data
  end
  haml :snapshot, :layout => :rummy
end

get '/sprints.json' do
  c= Curl::Easy.new("https://#{session[:login_name]}:#{session[:password]}@www10.v1host.com/sandp/rest-1.v1/Data/Timebox?sel=Name,BeginDate,EndDate&where=%28Schedule.Name=%27SAS_Global_Sprint_Schedule%27%29")
  c.perform
  sprints = []
  Nokogiri::XML(c.body_str).xpath('//Assets/Asset').each do |row|
    sprints.push({
      :name => row.at_xpath('Attribute[@name="Name"]/text()').to_s,
      :begin_date => row.at_xpath('Attribute[@name="BeginDate"]/text()').to_s,
      :end_date => row.at_xpath('Attribute[@name="EndDate"]/text()').to_s,
    })
  end
  sprints.to_json
end

get '/status' do
  haml :status, :layout => :rummy
end

get '/status.json' do
  content_type :json
  session[:data].to_json
end

get '/history.json' do
  content_type :json
  ret = {}
  session[:data].each do |hash|
    c = Curl::Easy.new("https://#{session[:login_name]}:#{session[:password]}@www10.v1host.com/sandp/rest-1.v1/Hist/Story/#{hash[:story_id]}?sel=ChangeDate,Status.Name&where=Status.Name=%27In%20Progress%27&sort=ChangeDate")
    c.perform
    r = []
    Nokogiri::XML(c.body_str).xpath('//History/Asset').each do |row|
      r.push(row.at_xpath('Attribute[@name="ChangeDate"]/text()').to_s)
    end
    ret[hash[:story_id]] = r
  end
  ret.to_json
end
