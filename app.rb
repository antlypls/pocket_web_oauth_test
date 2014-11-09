require 'rubygems'
require 'bundler'
Bundler.require(:default)

class App < Sinatra::Base
  enable :logging
  enable :sessions

  set :views, File.expand_path('../views', __FILE__)

  CALLBACK_URL = "http://localhost:#{ENV['PORT']}/oauth/callback"

  Pocket.configure do |config|
    config.consumer_key = ENV['CONSUMER_KEY']
  end

  get '/reset' do
    logger.info 'GET /reset'
    session.clear
  end

  get '/' do
    logger.info 'GET /'
    logger.info "session: #{session.inspect}"

    if session[:access_token]
      slim :index_authorized
    else
      slim :index
    end
  end

  get '/oauth/connect' do
    logger.info 'OAUTH CONNECT'
    session[:code] = Pocket.get_code(redirect_uri: CALLBACK_URL)
    new_url = Pocket.authorize_url(code: session[:code], redirect_uri: CALLBACK_URL)
    logger.info "new_url: #{new_url}"
    logger.info "session: #{session}"
    redirect new_url
  end

  get '/oauth/callback' do
    logger.info 'OAUTH CALLBACK'
    logger.info "request.url: #{request.url}"
    logger.info "request.body: #{request.body.read}"
    result = Pocket.get_result(session[:code], redirect_uri: CALLBACK_URL)
    session[:access_token] = result['access_token']
    logger.info result['access_token']
    logger.info result['username']
    logger.info session[:access_token]
    logger.info "session: #{session}"
    redirect '/'
  end

  get '/add' do
    client = Pocket.client(access_token: session[:access_token])
    info = client.add url: 'http://getpocket.com'
    slim :info, locals: { info: info }
  end

  get '/retrieve' do
    client = Pocket.client(access_token: session[:access_token])
    info = client.retrieve(detailType: :complete, count: 1)
    slim :info, locals: { info: info }
  end
end
