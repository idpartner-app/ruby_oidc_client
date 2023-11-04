# frozen_string_literal: true

require_relative "ruby_oidc_client/version"
require "json/jwt"
require "net/http"
require "uri"
require "base64"

module RubyOidcClient
  class IDPartner
    SUPPORTED_AUTH_METHODS = [
      "client_secret_basic",
      "tls_client_auth",
      "private_key_jwt" # For backward compatibility
    ].freeze
    SIGNING_ALG = "PS256"
    ENCRYPTION_ALG = "RSA-OAEP"
    ENCRYPTION_ENC = "A256CBC-HS512"

    attr_reader :config, :endpoints, :provider_keys

    def initialize(config)
      raise ArgumentError, "Config missing." unless config

      default_config = {
        account_selector_service_url: "https://auth-api.idpartner.com/oidc-proxy",
        token_endpoint_auth_method: "client_secret_basic",
        jwks: nil,
        client_secret: nil
      }

      @config = default_config.merge(config)

      unless SUPPORTED_AUTH_METHODS.include?(@config[:token_endpoint_auth_method])
        raise ArgumentError,
              "Unsupported token_endpoint_auth_method '#{config[:token_endpoint_auth_method]}'. It must be one of (#{SUPPORTED_AUTH_METHODS.join(", ")})"
      end

      client_secret_config = @config[:token_endpoint_auth_method] == "client_secret_basic" ? { client_secret: @config[:client_secret] } : {}

      jwks_config = if @config[:jwks]
                      {
                        authorization_encrypted_response_alg: ENCRYPTION_ALG,
                        authorization_encrypted_response_enc: ENCRYPTION_ENC,
                        id_token_encrypted_response_alg: ENCRYPTION_ALG,
                        id_token_encrypted_response_enc: ENCRYPTION_ENC,
                        request_object_signing_alg: SIGNING_ALG
                      }
                    else
                      {}
                    end

      @config = @config.merge({
                                authorization_signed_response_alg: SIGNING_ALG,
                                id_token_signed_response_alg: SIGNING_ALG
                              }).merge(client_secret_config).merge(jwks_config)
    end

    def generate_proofs
      {
        state: SecureRandom.urlsafe_base64(64),
        nonce: SecureRandom.urlsafe_base64(64),
        code_verifier: SecureRandom.urlsafe_base64(64)
      }
    end

    def get_authorization_url(query, proofs, scope, extra_authorization_params = {})
      raise ArgumentError, "The URL query parameters are required." unless query
      raise ArgumentError, "The scope parameters are required." unless scope
      raise ArgumentError, "The proofs parameters are required." unless proofs
      raise ArgumentError, "The extra_authorization_params parameters are required." unless extra_authorization_params

      if query[:iss].nil?
        return "#{config[:account_selector_service_url]}/auth/select-accounts?client_id=#{config[:client_id]}&visitor_id=#{query[:visitor_id]}&scope=#{scope}&claims=#{extract_claims(extra_authorization_params[:claims]).join("+")}"
      end

      @config[:iss] = query[:iss]
      obtain_well_known_config_endpoints

      extra_authorization_params[:claims] = extra_authorization_params[:claims]&.to_json
      extended_authorization_params = {
        redirect_uri: config[:redirect_uri],
        code_challenge_method: "S256",
        code_challenge: generate_code_challenge(proofs[:code_verifier]),
        state: proofs[:state],
        nonce: proofs[:nonce],
        scope: scope,
        response_type: "code",
        client_id: config[:client_id],
        'x-fapi-interaction-id': SecureRandom.uuid,
        identity_provider_id: query[:idp_id],
        idpartner_token: query[:idpartner_token],
        response_mode: "jwt"
      }.merge(extra_authorization_params).compact

      pushed_authorization_request_params = extended_authorization_params
      pushed_authorization_request_params = { request: create_request_object(extended_authorization_params) } if config[:jwks]

      request_uri = push_authorization_request(pushed_authorization_request_params)["request_uri"]
      query_params = URI.encode_www_form(request_uri: request_uri)
      "#{endpoints[:authorization_endpoint]}?#{query_params}"
    end

    def public_jwks
      return {} unless config[:jwks]

      jwk_set = JSON::JWK::Set.new(JSON.parse(config[:jwks]))
      public_jwks = jwk_set.collect do |jwk|
        public_jwk = jwk.to_key.public_key.to_jwk
        public_jwk.merge("alg" => jwk["alg"], "use" => jwk["use"]).compact
      end

      { "keys" => public_jwks }
    end

    def token(query, proofs)
      decoded_jwt = decode_jwt(query[:response])
      basic_auth_credentials = Base64.strict_encode64("#{config[:client_id]}:#{config[:client_secret]}")
      payload = {
        code: decoded_jwt["code"],
        code_verifier: proofs[:code_verifier],
        grant_type: "authorization_code",
        redirect_uri: config[:redirect_uri]
      }

      uri = URI(endpoints[:token_endpoint])
      http = Net::HTTP.new(uri.host, uri.port)
      headers = {
        "Authorization" => "Basic #{basic_auth_credentials}",
        "Content-Type" => "application/x-www-form-urlencoded",
        "Accept" => "application/json"
      }
      token_request = Net::HTTP::Post.new(uri.request_uri, headers)
      token_request.set_form_data(payload)
      token_response = http.request(token_request)
      raise "Failed to exchange token: #{token_response.body}" unless token_response.is_a?(Net::HTTPSuccess)

      JSON.parse(token_response.body)
    end

    def userinfo(access_token)
      uri = URI(endpoints[:userinfo_endpoint])
      http = Net::HTTP.new(uri.host, uri.port)
      headers = {
        "Authorization" => "Bearer #{access_token}",
        "Accept" => "application/json"
      }

      userinfo_request = Net::HTTP::Get.new(uri.request_uri, headers)
      userinfo_response = http.request(userinfo_request)

      raise "Failed to retrieve userinfo: #{userinfo_response.body}" unless userinfo_response.is_a?(Net::HTTPSuccess)

      JSON.parse(userinfo_response.body)
    rescue StandardError => e
      raise "Failed to fetch well-known config: #{e.message}"
    end

    private

    def extract_claims(claims_object)
      return [] unless claims_object.is_a?(Hash)

      userinfo_keys = claims_object[:userinfo]&.keys || []
      id_token_keys = claims_object[:id_token]&.keys || []

      (userinfo_keys + id_token_keys).uniq
    end

    def obtain_well_known_config_endpoints
      uri = URI("#{config[:iss]}/.well-known/openid-configuration")
      http = Net::HTTP.new(uri.host, uri.port)
      headers = { "Accept" => "application/json" }
      request = Net::HTTP::Get.new(uri.request_uri, headers)
      response = http.request(request)
      raise "Failed to retrieve well-known: #{response.body}" unless response.is_a?(Net::HTTPSuccess)
      well_known_config = JSON.parse(response.body)
      @endpoints = {
        authorization_endpoint: well_known_config["authorization_endpoint"],
        token_endpoint: well_known_config["token_endpoint"],
        userinfo_endpoint: well_known_config["userinfo_endpoint"],
        pushed_authorization_request_endpoint: well_known_config["pushed_authorization_request_endpoint"],
        jwks_uri: well_known_config["jwks_uri"]
      }
    rescue StandardError => e
      raise "Failed to fetch well-known config: #{e.message}"
    end

    def create_request_object(params)
      extended_params = params.merge({
                                       iss: config[:client_id],
                                       aud: config[:iss],
                                       exp: Time.now.to_i + 60,
                                       iat: Time.now.to_i,
                                       nbf: Time.now.to_i
                                     })

      sig_key = sig_key()
      jwt = JSON::JWT.new(extended_params)
      jwt.sign(sig_key, sig_key["alg"]).to_s
    end

    def push_authorization_request(request_object)
      uri = URI(endpoints[:pushed_authorization_request_endpoint])
      http = Net::HTTP.new(uri.host, uri.port)
      basic_auth_credentials = Base64.strict_encode64("#{config[:client_id]}:#{config[:client_secret]}")
      headers = {
        "Authorization" => "Basic #{basic_auth_credentials}",
        "Content-Type" => "application/x-www-form-urlencoded",
        "Accept" => "application/json"
      }
      par_request = Net::HTTP::Post.new(uri.request_uri, headers)
      par_request.set_form_data(request_object)
      par_response = http.request(par_request)
      raise "Failed to push authorization request: #{par_response.body}" unless par_response.is_a?(Net::HTTPSuccess)

      JSON.parse(par_response.body)
    rescue StandardError => e
      raise "An error occurred: #{e.message}"
    end

    def generate_code_challenge(code_verifier)
      Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).gsub(/=+$/, "")
    end

    def sig_key
      jwk_set = JSON::JWK::Set.new(JSON.parse(config[:jwks]))
      jwk_set.find { |j| j[:use] == "sig" }
    end

    def enc_key
      jwk_set = JSON::JWK::Set.new(JSON.parse(config[:jwks]))
      jwk_set.find { |j| j[:use] == "enc" }
    end

    def decode_jwt(jwt_str)
      if jwt_str.split(".").length == 5
        jwe = JSON::JWT.decode(jwt_str, enc_key)
        jwt_str = jwe.plain_text
      end

      kid = JSON::JWT.decode(jwt_str, :skip_verification).kid
      sig_key = provider_key(kid)
      JSON::JWT.decode(jwt_str, sig_key)
    end

    def provider_key(kid)
      fetch_provider_keys unless provider_keys
      @provider_keys[kid] || (raise "No provider key found for kid: #{kid}")
    end

    def fetch_provider_keys
      jwks_uri = endpoints[:jwks_uri]
      fetched_provider_keys = JSON::JWK::Set::Fetcher.fetch(jwks_uri, kid: nil, auto_detect: false)
      @provider_keys = {}
      fetched_provider_keys.each do |key|
        @provider_keys[key["kid"]] = key
      end
    end
  end
end
