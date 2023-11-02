# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyOidcClient::IDPartner do
  let(:config) do
    {
      client_id: "F8W8ZKUiyRX_0noOLa943",
      redirect_uri: "http://localhost:3001/button/oauth/callback",
      client_secret: "edhQyIjEg1HV9sNy2W4U-c6TVRQLsYTq2z8P6eg8X8a6eSr6HJaz943foNADNLipCFpO-zb8minhBDyIlDVbTw"
    }
  end
  let(:id_partner) { described_class.new(config) }

  it "has a version number" do
    expect(RubyOidcClient::VERSION).not_to be nil
  end

  describe "#initialize" do
    it "initializes with a config hash" do
      expect(id_partner).to be_a(described_class)
    end

    it "raises an error if config is missing" do
      expect { described_class.new(nil) }.to raise_error(ArgumentError, "Config missing.")
    end

    it "raises an error for unsupported token_endpoint_auth_method" do
      config[:token_endpoint_auth_method] = "unsupported_method"
      expect { described_class.new(config) }.to raise_error(ArgumentError)
    end

    it "assigns a default token_endpoint_auth_method" do
      expect(id_partner.config[:token_endpoint_auth_method]).to eq("client_secret_basic")
    end
  end

  describe "#generate_proofs" do
    it "generates a proofs hash" do
      proofs = id_partner.generate_proofs
      expect(proofs).to be_a(Hash)
      expect(proofs.keys).to contain_exactly(:state, :nonce, :code_verifier)
    end
  end

  describe "#get_authorization_url", :vcr do
    let(:query) { { iss: "http://localhost:9001/oidc" } }
    let(:proofs) { { state: "state", nonce: "nonce", code_verifier: "code_verifier" } }
    let(:scope) { %w[openid email profile] }
    let(:prompt) { "consent" }

    it "returns an authorization url" do
      url = id_partner.get_authorization_url(query, proofs, scope, prompt, nil)
      expect(url).to eq("http://localhost:9001/oidc/auth?request_uri=urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3ABfdJw4QAuMr5Ir6a-Uypx")
    end

    describe "#token" do
      it "exchanges a code for a token" do
        id_partner.get_authorization_url(query, proofs, scope, prompt, nil)
        token_response = id_partner.token(
          { response: "eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ii1NXzl2cUppMHRTWURlWEZoM2Nsdlo3MG50Qm9zVVZUOWFxQi0tMlNRaVUifQ.eyJjb2RlIjoiVEJvYTlLR1lsU2RPMGZGdnhJMklYV2NnV3diT1VVYlpQNjB6VWh5TkQyVyIsInN0YXRlIjoib3FKYm13eDZuQ1ZDRF9LanQ2cE9kbjZpZTF4R3REY2VlTHRiN0x4azRBYzBIeWxEMzBxd241cGdyYm9rRjBmQW53aVBOT1JPQWk4ZWtGYlhXbHJIU3ciLCJhdWQiOiJGOFc4WktVaXlSWF8wbm9PTGE5NDMiLCJleHAiOjE2OTg4Njc3NDYsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6OTAwMS9vaWRjIn0.XACQeu39-bNTLSW0AKh5IvNnjzQhCsTejvPpYEt-Obcyu6D-Z6hm7r-9q_TM5eRL9S2M2D9TqzOMro_ncZ7GUR4ERUn1sCmHxBE_amSUeecXIifTYonUPnRf3AfzJ3hDyewXQ2nyJt2wVmFe2WXPkJsbFZadZnjJt9hu5TG7QH2wPraZj7JcfERF6kbmu30NzPC-qW8DmzH3B5KpJ74S3WkUSgq0C3S_BHDbzYKjuAnKtrxt92jFlvthYApaLrimNKxjvZCe38Yd8G0kq8EWVi3X4pX2GF9cGc7mheZB88gN_AEWiSgPuUMKOWpEDMu_TDAetZix8sBtUnDFnz7vcg" }, proofs
        )
        expect(token_response["access_token"]).to eq("NHtB5NG6woOQSeGn5BQr5qAu6ai8B_edu8S9VpfrAXY")
      end
    end

    describe "#userinfo", :vcr do
      let(:access_token) { "NHtB5NG6woOQSeGn5BQr5qAu6ai8B_edu8S9VpfrAXY" }

      it "retrieves user info" do
        id_partner.get_authorization_url(query, proofs, scope, prompt, nil)
        userinfo_response = id_partner.userinfo(access_token)
        expect(userinfo_response["sub"]).to eq("32f0998fc710c68c7661f73d12bf07e987a4cb688b3dfa48a6ee27f95262ee22")
        expect(userinfo_response["email"]).to eq("PhilipHLovett@mikomotest.com")
        expect(userinfo_response["family_name"]).to eq("Lovett")
        expect(userinfo_response["given_name"]).to eq("Philip")
      end
    end
  end

  describe "#get_public_jwks" do
    it "returns a hash of public JWKS" do
      jwks = id_partner.public_jwks
      expect(jwks).to be_a(Hash)
    end
  end
end
