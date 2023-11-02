# frozen_string_literal: true

require "sinatra"
require_relative "../../lib/id_partner"

class App < Sinatra::Base
  config = JSON.parse(File.read("config.json"))

  set :bind, "0.0.0.0"
  set :port, config["port"]
  set :public_folder, "#{File.dirname(__FILE__)}/public"
  enable :sessions

  id_partner = RubyOidcClient::IDPartner.new({
                                               account_selector_service_url: "http://localhost:9002",
                                               client_id: config["client_id"],
                                               client_secret: config["client_secret"],
                                               redirect_uri: config["redirect_uri"]
                                             })

  get "/" do
    erb :index, locals: { title: "RP Client Secret Example", config: config }
  end

  get "/button/oauth" do
    scope = ["openid", "offline_access", "email", "profile", "birthdate address"]
    prompt = "consent"
    proofs = id_partner.generate_proofs
    session[:proofs] = proofs
    session[:issuer] = params[:iss]
    redirect id_partner.get_authorization_url(params, proofs, scope, prompt, nil)
  end

  get "/button/oauth/callback" do
    token = id_partner.token(params, session[:proofs])
    userinfo = id_partner.userinfo(token["access_token"])
    content_type :json
    userinfo.to_json
  end

  get "/jwks" do
    content_type :json
    id_partner.public_jwks.to_json
  end

  run! if app_file == $PROGRAM_NAME
end
