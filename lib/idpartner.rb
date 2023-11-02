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

    attr_reader :config, :endpoints

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
                                client_id: @config[:client_id],
                                token_endpoint_auth_method: @config[:token_endpoint_auth_method],
                                redirect_uri: @config[:redirect_uri],
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

    def get_authorization_url(query, proofs, scope, prompt, claims_object)
      client_id = config[:client_id]
      account_selector_service_url = config[:account_selector_service_url]

      raise ArgumentError, "The URL query parameters are required." unless query
      raise ArgumentError, "The proofs parameters are required." unless proofs
      raise ArgumentError, "The scope parameters are required." unless scope

      iss = query[:iss]
      visitor_id = query[:visitor_id]
      idpartner_token = query[:idpartner_token]

      claims = extract_claims(claims_object)

      if iss.nil?
        return "#{account_selector_service_url}/auth/select-accounts?client_id=#{client_id}&visitor_id=#{visitor_id}&scope=#{scope.join("+")}&claims=#{claims.join("+")}"
      end

      @config[:provider_url] = iss
      obtain_well_known_config_endpoints

      state, nonce, code_verifier = proofs.values_at(:state, :nonce, :code_verifier)
      code_challenge = generate_code_challenge(code_verifier)

      authorization_params = {
        redirect_uri: config[:redirect_uri],
        code_challenge_method: "S256",
        code_challenge: code_challenge,
        state: state,
        nonce: nonce,
        scope: scope.join(" "),
        prompt: prompt,
        response_type: "code",
        client_id: client_id,
        nbf: Time.now.to_i,
        'x-fapi-interaction-id': SecureRandom.uuid,
        identity_provider_id: query[:idp_id],
        idpartner_token: idpartner_token,
        claims: claims_object&.to_json,
        response_mode: "jwt"
      }.compact

      pushed_authorization_request_params = authorization_params
      pushed_authorization_request_params = { request: create_request_object(authorization_params) } if config[:jwks]

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
      # Assuming you have a method to decode the token
      verified_token = verify_jws(query[:response])

      # Create the credentials for Basic Authorization header
      basic_auth_credentials = Base64.strict_encode64("#{config[:client_id]}:#{config[:client_secret]}")

      # Prepare the payload for the token exchange request
      payload = {
        code: verified_token["code"],
        code_verifier: proofs[:code_verifier],
        grant_type: "authorization_code",
        redirect_uri: config[:redirect_uri]
      }

      # Send the token exchange request
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
      # Prepare the URI and headers for the userinfo request
      uri = URI(endpoints[:userinfo_endpoint])
      http = Net::HTTP.new(uri.host, uri.port)
      headers = {
        "Authorization" => "Bearer #{access_token}",
        "Accept" => "application/json"
      }

      # Send the userinfo request
      userinfo_request = Net::HTTP::Get.new(uri.request_uri, headers)
      userinfo_response = http.request(userinfo_request)

      # Check the response and parse the userinfo data
      raise "Failed to retrieve userinfo: #{userinfo_response.body}" unless userinfo_response.is_a?(Net::HTTPSuccess)

      JSON.parse(userinfo_response.body)
    end

    private

    def extract_claims(claims_object)
      return [] unless claims_object.is_a?(Hash)

      userinfo_keys = claims_object[:userinfo]&.keys || []
      id_token_keys = claims_object[:id_token]&.keys || []
      (userinfo_keys + id_token_keys).uniq
    end

    def obtain_well_known_config_endpoints
      uri = URI("#{config[:provider_url]}/.well-known/openid-configuration")
      response = Net::HTTP.get(uri)
      well_known_config = JSON.parse(response)
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
                                       aud: config[:provider_url],
                                       exp: Time.now.to_i + 60,
                                       iat: Time.now.to_i
                                     })
      jwt = JSON::JWT.new(extended_params)
      private_key = parse_private_key(config[:jwks])
      jwt.sign(private_key, :PS256).to_s
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

    def parse_private_key(jwks)
      jwk_set = JSON::JWK::Set.new(JSON.parse(jwks))
      jwk = jwk_set.select { |j| j[:use] == "sig" }.first
      jwk.to_key
    end

    def verify_jws(jwt)
      # Obtain the JWKS from the issuer
      jwks_uri = URI(endpoints[:jwks_uri])
      jwks_response = Net::HTTP.get_response(jwks_uri)
      raise "Failed to fetch JWKS: #{jwks_response.body}" unless jwks_response.is_a?(Net::HTTPSuccess)

      jwks_data = JSON.parse(jwks_response.body)

      # Decode the JWT without verification to obtain the header
      unverified_jwt = JSON::JWT.decode jwt, :skip_verification
      kid = unverified_jwt.header[:kid]
      sig_key_data = jwks_data["keys"].find { |key| key["kid"] == kid }
      raise "No signing key found in JWKS" unless sig_key_data

      sig_key = JSON::JWK.new(sig_key_data)

      # Now verify the JWT signature
      JSON::JWT.decode jwt, sig_key
    end
  end
end
