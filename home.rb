require 'sinatra'
require 'haml'
require 'curb'
require 'nokogiri'
require 'json'
require 'dalli'
require 'date'

enable :sessions
set :cache, Dalli::Client.new

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
  session[:sprint] = nil
  settings.cache.get('sprints').each do |sprint|
    settings.cache.set("data_#{sprint_split(sprint[:name])}", nil)
  end
  settings.cache.set('sprints', nil)
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
    redirect '/sprint'
  end
end

get '/unauthorized' do
  haml :unauthorized
end

get '/sprint' do
  haml :sprint
end

get '/change_sprint' do
  session[:sprint] = sprint_split(params[:sprint])
  redirect '/snapshot'
end

get '/snapshot' do
  unless not settings.cache.get("data_#{session[:sprint]}").nil?
    sp = /^[0-9]/.match(session[:sprint]) ? "Sprint%20" + session[:sprint] : session[:sprint]
    c = Curl::Easy.new("https://#{session[:login_name]}:#{session[:password]}@www10.v1host.com/sandp/rest-1.v1/Data/Story\?sel\=Name,Estimate,Number,Status.Name\&where\=%28Team.Name\=%27SAS%20EMEA%20Integration%20Team%27\;Timebox.Name\=%27" + sp + "%27%29")
    c.perform
    data = []
    Nokogiri::XML(c.body_str).xpath('//Assets/Asset').each do |row|
      data.push({
        :number => row.at_xpath('Attribute[@name="Number"]/text()').to_s,
        :status => row.at_xpath('Attribute[@name="Status.Name"]/text()').to_s,
        :name => row.at_xpath('Attribute[@name="Name"]/text()').to_s,
        :estimate => ((row.at_xpath('Attribute[@name="Estimate"]/text()').to_s == "")? "-" : row.at_xpath('Attribute[@name="Estimate"]/text()').to_s),
        :story_id => row.at_xpath("@id").to_s.split(':').last
      })
    end
    settings.cache.set("data_#{session[:sprint]}", data)
  end
  haml :snapshot, :layout => :rummy
end

get '/sprints.json' do
  unless not settings.cache.get('sprints').nil?
    c= Curl::Easy.new("https://#{session[:login_name]}:#{session[:password]}@www10.v1host.com/sandp/rest-1.v1/Data/Timebox?sel=Name,BeginDate,EndDate&where=%28Schedule.Name=%27SAS_Global_Sprint_Schedule%27%29")
    c.perform
    sprints = []
    Nokogiri::XML(c.body_str).xpath('//Assets/Asset').each do |row|
      name = row.at_xpath('Attribute[@name="Name"]/text()').to_s
      sprints.push({
        :name => name,
        :begin_date => row.at_xpath('Attribute[@name="BeginDate"]/text()').to_s,
        :end_date => row.at_xpath('Attribute[@name="EndDate"]/text()').to_s
      })
    end
    settings.cache.set('sprints', sprints)
  end
  settings.cache.get('sprints').to_json
end

get '/status' do
  haml :status, :layout => :rummy
end

get '/status.json' do
  content_type :json
  settings.cache.get("data_#{session[:sprint]}").to_json
end

get '/history.json' do
  content_type :json
  ret = {}
  settings.cache.get("data_#{session[:sprint]}").each do |hash|
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

helpers do 
  def sprint_split(text)
    text.split(' ').last
  end

  def sprint_display
    sp = nil
    settings.cache.get('sprints').each do |sprint|
      if session[:sprint] == sprint_split(sprint[:name])
        sp = sprint
        break
      end
    end
    begin_date, end_date = Date.strptime(sp[:begin_date], "%Y-%m-%d"), Date.strptime(sp[:end_date], "%Y-%m-%d")
    if end_date >= Date.today
      begin_date < Date.today ? "Current Sprint. #{end_date.mjd - Date.today.mjd} day(s) left!" : "Sprint starts in #{begin_date.mjd - Date.today.mjd} day(s)"
    else
      "Closed (#{begin_date.strftime('%d-%b-%Y')} to #{end_date.strftime('%d-%b-%Y')})"
    end
  end
end
