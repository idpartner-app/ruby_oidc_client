# frozen_string_literal: true

require "spec_helper"

RSpec.describe RubyOidcClient::IDPartner do
  jwks_json = '{"keys":[{"kty":"RSA","kid":"3eL_LSEgEHCNa45mwU7zZ83SEHvX2MesdKWcP14jQ8s","use":"sig","alg":"PS256","e":"AQAB","n":"0bml-h4oJEkmonIBzKZWKoaEt_jn5exY06RwOY-EB6Xp5RPbnQj8AdEW6tl8XBnpdJzhYMb7dnySzRj--jMxG_K8ZhTjLG68og4sm66H08QhWUey1lCN3vTvni8tCZtc7iPKgXJXTzyIkOse-UVkZwhQngPCh7MWjFcG4UfF97APl8XKcjpyshKakfYSpfbKoFqvRbqlJAKCyiwnVf3Ea-RXjh9spLsd77qTNMJEQt14PJxruYXTHPPubKvTJRqwR_ObxYrFxE5h8UZLFk8QYd6k_qKXdV0h2KNuu-PzmyIq7RmQMTr7M4xWexLzrQ7msnsPFJHncXfUD1-jQMtK5Q","d":"gDpoFuM1W-o16wCVxRC2gk24-9r9voChVtWloCv1Z8-zkFJx5jPGET5MKs9Kz-0v5hK9YjSHL0y_XRM5YrTGA_aH5kpDE7mpL9RGxfESLxIt6a6C07Jw668KiscBXGxXh2rut_K3G0VBool_aJ1a4_wbfmGCIQIIeUoEdN0zV1p84ZfCTpwDbbxfnK83ia6ke_RQmoKBjrUyiciUF6jiZEfb-1Vm7aE2NWU8yhmiZ14VAq0YR3xq0OlE8FxjWpr9Lr1i-5Gy-LDOnMRM4zfvYqC_FsiOQ-wGxAxMme_-tm3B05OIsk_O82YpyxpBZYgHn7AK7xahAQMMLiL2y2viyQ","p":"7UUoo8AKof_cIhRBSwmFhTt7_e8BZ7w0uPCAcSv4DNepCoUoTSNDHuuUmgPEULmQplHwhH-wW7ACVvylSZT4JYq-qwSVr9wJoFAYQDYiJizP73eVnFkfqiv2-xwPQaFONwGGxixuz0r8j16Tpe4iMK8Hy-LYpjucvTp6RrNHgls","q":"4kfZ2710YTnCXUsgga-lZxxDIloJ55iLtRSRizRGyxVCNkH1IMoo6pf59AiPkyk1iWYTx4IS_SkelSPWNtJLnFKmgocYikILsiVVSOoI1vkq9la3FTmJkRNzPfTtFWVf0_e0Ff7dkQxr3XBEZUVS0o9-y_V3k7sMsnfuajjva78","dp":"WFk_J7Izg1z1SA9IvLsf55tdsRFU8Z6H9zE-cmWP6KBJBmzMs-Rkctf_rlWmvPRL41Jxf7TYI1vnkyJiHYMF31zJYH7FigUh5HrOfOJrVtGq350krWIWQ1Q5lAk_uQ1qRVshJxuWa0OdxXjO-6MvQfd6rLWcPFHILEHhFABfqS8","dq":"GMe3kvnfadpSb7cPe0RJ_823iGaF2Sf6fL0g5za1Xf4Y_yof9xRMgMxd4hyh5ILJyx8zoVCcVb8QC1MeXWiQQTFH7NlwlYuADmVKPq7qguhMjSeX6yoe55VStIFDCWnNob_pp9L-XqkWkux9gP2jgU2XnCxoiPQeAtlhcZ6Eka8","qi":"Rh3yHepiLVy2gxHepFp2Yi9qSCULNCySjpDy9eeegEHQMIlH5cdO6Q5UmAtQZwoexWgXhmL8hPcgKumcGq0ZG_EpStIy176-McxtkmpbycY8Bfw6rk1FH2Sfn44oIB2JxUm8yHouh6UMz3e_WeisrmotbeAmH0NtG8DyPkTSgmA"},{"kty":"RSA","kid":"u64VsIB-cxX3NHf1nYn1OtBXmWWQfZZp2BVN1rZL6XU","use":"enc","alg":"RSA-OAEP","e":"AQAB","n":"0CIIQ8dAvOfVE38owR4I03lu1oHmCJz0vSKCRWVyNXSfXwl00eH6JmyDC8sFo2h66iU8vNBauYELoxNf4yT9hXsEcDgJcf9NPW186LSttqqgZ8wSycS7Pn3YTfbzH45R5mH_1zvsKnI8Xwi2DibpOht0bVWStG-EXkAkj6YQdSR1cMQXvtBIetWP6cPx7kG-qzjze3mvtIucnKRnphbW31Bker2Ykur3_ySqXJpCxUx3TchL5-pckTfS9Na6VALIBTLR8dHPq1GJXVgQOCh6GrY7ljIY7ZbkJW2_n1SgyNT49SuxBrPWKiIJW2uIdgMtq3Fp-BFMqJJGaqQ_W2jtAw","d":"x7A_ObhMNnI_jusrkM1eLneNjiUnLRBaB7S6RBam0v7HgYkzGcO0G3V07bWl_Tfa5hdABO_qe5yCK74E-4ub6ZszkO9SsJr_4nXPp_zhxiZCrBOx2v_znmtjQroyXQ5RKbbQnhKR7c-YeJ2E_mL61ZNNyzCVBqUP3NWxvljX5WqQiwsap-RN2ZiCXKrGiC_pG59uS5NSTNqf2cgXy0eSlQqt-7T6ZAZtsCz0I6pUYfHbXa3lIHCCRtTDWoVIoaKUa01FqyBeE04V6DvU9AOZWcK670cXbzhG1kkEk5HHYrQabPrBFXtRaOrApaasGDbZDv4fRW31WnNYLuhllPcQMQ","p":"55y41df36jmE0eQmLtI1jLAq7Adw-AhweUUL-Sklf4GkzCEnJ2wVguiCni8NrFMRiCrM95ntFwT6o1neuG4St3rK5wvE_SOYbLvw2MMnjqLVr4zbbDuLJ-w8-SeqDuFRxHkR6xp8J-YwXeD5N4blceEqU36XHpChcZkzoSWCO68","q":"5gxo1-MeuxMk_-RbS85hWMyQzVOBXGpuUlDpFELB2FxjAaaEN9bDRplWfVwTL-txN24NhFZepd8Bf7NL9nAGmGtTiEWhK5jQZz_WeXA6zRLwcm1v9Hbl516baMQy1cOa5VUyrGTsjVO3Q35j8fpRFa_RK-h3U6_bdDpO3UMyFO0","dp":"TEaZvJseYz3EFxeK15qU1htiV07wDk9BMz7g_ZJmbgJ1EmDMszfuMal-8rdOSnUk7fIihFxl71HNdSRwq85cTZ6b2dFPc4pYdV7Dp69FhLztoJ3D2XYWkvRC9E7yu2nK8uhoVUPopX8yaIhhqr67K3Da7ppfDErXUEEC9swSgrM","dq":"J_XP4HBbTjOtIaYRFcHrtvkRzhjLR7pVH4dedV6DPYoOyKKcJPbxRLouA-iSjKhhKje7sVkvZ7CtGfmTIGOlQaSjBfDSZjhNOyIjp0SPcj_v9HB-GgDtPpt4c2JhUjCAH4YFH10ImiQImXjC861_mDzKIM5oq-jIPhBC0rxxXqE","qi":"exJQqZEtA7p9XxItMAip-OTQ7W6n40xexi8PrJdfEvbrk0aAqO4-ixFyqlQnkwKGQt-IIBgwxjRPwEMMMufd_iLbc0EL1QZN370hSCyqIReGa5qH0W2vvoRf4QfmIiEWumfVWTOb9isCW1nlrPnCkBgGrLxTyZKS_BWwez7eDXQ","enc":"A256CBC-HS512"}]}'
  let(:config) do
    {
      client_id: "CLIENT_ID",
      redirect_uri: "http://localhost:3001/button/oauth/callback",
      client_secret: "CLIENT_SECRET"
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

  describe "#get_authorization_url", :vcr, record: :new_episodes do
    let(:query) { { iss: "http://localhost:9001/oidc" } }
    let(:proofs) { { state: "state", nonce: "nonce", code_verifier: "code_verifier" } }
    let(:scope) { %w[openid email profile] }
    let(:prompt) { "consent" }

    it "returns an authorization url" do
      url = id_partner.get_authorization_url(query, proofs, scope, prompt, nil)
      expect(url).to eq("http://localhost:9001/oidc/auth?request_uri=urn%3Aietf%3Aparams%3Aoauth%3Arequest_uri%3ABfdJw4QAuMr5Ir6a-Uypx")
    end

    describe "#token" do
      it "exchanges a code from a JWS for a token" do
        id_partner.get_authorization_url(query, proofs, scope, prompt, nil)
        token_response = id_partner.token(
          { response: "eyJhbGciOiJQUzI1NiIsInR5cCI6IkpXVCIsImtpZCI6Ii1NXzl2cUppMHRTWURlWEZoM2Nsdlo3MG50Qm9zVVZUOWFxQi0tMlNRaVUifQ.eyJjb2RlIjoiVEJvYTlLR1lsU2RPMGZGdnhJMklYV2NnV3diT1VVYlpQNjB6VWh5TkQyVyIsInN0YXRlIjoib3FKYm13eDZuQ1ZDRF9LanQ2cE9kbjZpZTF4R3REY2VlTHRiN0x4azRBYzBIeWxEMzBxd241cGdyYm9rRjBmQW53aVBOT1JPQWk4ZWtGYlhXbHJIU3ciLCJhdWQiOiJGOFc4WktVaXlSWF8wbm9PTGE5NDMiLCJleHAiOjE2OTg4Njc3NDYsImlzcyI6Imh0dHA6Ly9sb2NhbGhvc3Q6OTAwMS9vaWRjIn0.XACQeu39-bNTLSW0AKh5IvNnjzQhCsTejvPpYEt-Obcyu6D-Z6hm7r-9q_TM5eRL9S2M2D9TqzOMro_ncZ7GUR4ERUn1sCmHxBE_amSUeecXIifTYonUPnRf3AfzJ3hDyewXQ2nyJt2wVmFe2WXPkJsbFZadZnjJt9hu5TG7QH2wPraZj7JcfERF6kbmu30NzPC-qW8DmzH3B5KpJ74S3WkUSgq0C3S_BHDbzYKjuAnKtrxt92jFlvthYApaLrimNKxjvZCe38Yd8G0kq8EWVi3X4pX2GF9cGc7mheZB88gN_AEWiSgPuUMKOWpEDMu_TDAetZix8sBtUnDFnz7vcg" }, proofs
        )
        expect(token_response["access_token"]).to eq("NHtB5NG6woOQSeGn5BQr5qAu6ai8B_edu8S9VpfrAXY")
      end

      it "exchanges a code from a JWE for a token" do
        config[:jwks] = jwks_json
        id_partner.get_authorization_url(query, proofs, scope, prompt, nil)
        token_response = id_partner.token(
          { response: "eyJhbGciOiJSU0EtT0FFUCIsImVuYyI6IkEyNTZDQkMtSFM1MTIiLCJjdHkiOiJKV1QiLCJraWQiOiJ1NjRWc0lCLWN4WDNOSGYxblluMU90QlhtV1dRZlpacDJCVk4xclpMNlhVIiwiaXNzIjoiaHR0cDovL2xvY2FsaG9zdDo5MDAxL29pZGMiLCJhdWQiOiJKWXJMTzBKal93RGRRUk0ySmlyM2IifQ.RTCfCHa4FB3gdRpzY-jwFcLIAK43fqTjWNMogeElVo7awa6sTkuCotjA_0TyH13R-wzttl_BUPVALnlW9kqdOFuWznkj_erIiFNQTCVIsqm0ZQsFGHBvTDe_lbBYHwwQ1sLUOQExTafE6f5jqrdGN30ylF3HAJJbG3sRR1VBVJdZwck0iar0m5s__iJN0bqlMa-e3jkCyQYJBrKhsMCl1dNm0UnpgpA1Tl5ElVDPByDm9aErN5xe6c5Hw0GTVTKbii2Wk1YXwigTkhrw0dk1xedo8hT1MW90t083An-Y74iU93gJdb4lG6UAxa1bXLpYUJUjHa4dosXSJ22zOcWbaQ.NDyH71DNX_XNMNLYl49cyQ.2LXuEa-vxF4i76N7mKMOkS236Wh_lCP7eksrml_vfIDKea4KuFoHPRhdMUggiJdSS_ybZoyv876Uw-38lTRBaxYp8VSHZCCVdy5uPsr4GTzLt7vWBRw5XQkdNfv8qPpGx15uHpxWLSV_38GaSil__WTnq4RRUmv6IYlZbH4X-a_UojH_po4n98yDolxMQJUtHIWmwQCHH3G8bIiYryy-t79KQfX5s_yLdO6zjC_6MfTAs9EEFkBub2_d-IBujg7RnEGFJU3eLRlOB5W60McrJIe000LrzeE3ahDIY0Xxwy7qXAAXWq1bL0tExNBtLTRpdUCoR35xDwHgh0Mg4FCOcys8KCZtJrCFXhX4z3ctqcR0FIs_cNmxal-3EIUXY8GfvRXyD3pkePFW4Rlr4GTdThpz2rujL3LX6-QXCjmgHVUR-eQj1VDq9fIVC1PqsTh_OpHgwjyiqzWwNIQTnyrIPjKsiRI4n7Bm6UorY0_SEsS71AXw7OivUrTCKtCkzMJzACUtVaU1Hg5DMchqON-ZYArpJQmSQBk8Sz9GFGgT-WBuDMgAkdQOgf4z5PwsjeFf-akLt14BmRYiURbB5kTprEHvRF0eYkiG1yn_AwIGZNneRUh-qcoIotIgi2iazpVA6EpO0FY0WiF9Wh7gF-lrdIqBKTPL2VyMdjjDtWXqx04Q4IIv2hj3oMigSmvVQm1lTetPnvfPNhZ3gTeu9DT6tF-VSy9GvBY6AhNchyb2r-EvFpRfjZDu-ZX4yPKLajdRdNhpg8AqEvT4Uzq0dxKF7GKNB86QnE8kzcFxt1JWQ6ox_fqC2btvzXVveyQC4211CjqFAHKB2fSl33IY8EY2bUT76Gf1s4NcvUgfc_0Uo6026ljIzv8as6iWUPbs_99NYffMXvP3QYC7qHKbYfQjsy37EeBOig0sSw-Yi9de2v1dSbMDl5xlyrWBkAjX2PhzA1Sz9ioU4gxnQ0Z3QzcqXy8Ev1e1djbaPmXa_xwnvYsHn9bl50OyTW0IUdDZy3Oz.C-Yc1Z4TIywcPuzjwVkntTxy-1LCx5TIQ8Aygf2v_Pc" }, proofs
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
      config[:jwks] = jwks_json
      jwks = JSON.parse(jwks_json)
      public_jwks = id_partner.public_jwks

      jwks_kids = jwks['keys'].map { |key| key['kid'] }
      public_jwks_kids = public_jwks['keys'].map { |key| key['kid'] }

      expect(public_jwks_kids).to match_array(jwks_kids)

      private_key_fields = %w[d p q dp dq qi]
      public_jwks['keys'].each do |key|
        private_key_fields.each do |field|
          expect(key).not_to have_key(field), "Private key field '#{field}' exposed for kid '#{key['kid']}'"
        end
      end
    end
  end
end
