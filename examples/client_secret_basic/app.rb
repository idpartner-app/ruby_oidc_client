require 'sinatra'
require_relative '../../lib/id_partner'

class App < Sinatra::Base
  config = JSON.parse(File.read('config.json'))

  set :bind, '0.0.0.0'
  set :port, config['port']
  set :public_folder, File.dirname(__FILE__) + '/public'
  enable :sessions

  id_partner = RubyOidcClient::IDPartner.new({
    account_selector_service_url: 'http://localhost:9002',
    # client_id: 'JYrLO0Jj_wDdQRM2Jir3b',
    # client_secret: 'A_DqotsgHNlg5JP2rQ45WPxfQkLMirYTsMHJvIeIF0rBpQVgaf1RSx5Fhc4yzEQeG7nr4A_da0kjlbInMPo0NA',
    client_id: config['client_id'],
    client_secret: config['client_secret'],
    redirect_uri: config['redirect_uri'],
    # jwks: '{"keys":[{"kty":"RSA","kid":"3eL_LSEgEHCNa45mwU7zZ83SEHvX2MesdKWcP14jQ8s","use":"sig","alg":"PS256","e":"AQAB","n":"0bml-h4oJEkmonIBzKZWKoaEt_jn5exY06RwOY-EB6Xp5RPbnQj8AdEW6tl8XBnpdJzhYMb7dnySzRj--jMxG_K8ZhTjLG68og4sm66H08QhWUey1lCN3vTvni8tCZtc7iPKgXJXTzyIkOse-UVkZwhQngPCh7MWjFcG4UfF97APl8XKcjpyshKakfYSpfbKoFqvRbqlJAKCyiwnVf3Ea-RXjh9spLsd77qTNMJEQt14PJxruYXTHPPubKvTJRqwR_ObxYrFxE5h8UZLFk8QYd6k_qKXdV0h2KNuu-PzmyIq7RmQMTr7M4xWexLzrQ7msnsPFJHncXfUD1-jQMtK5Q","d":"gDpoFuM1W-o16wCVxRC2gk24-9r9voChVtWloCv1Z8-zkFJx5jPGET5MKs9Kz-0v5hK9YjSHL0y_XRM5YrTGA_aH5kpDE7mpL9RGxfESLxIt6a6C07Jw668KiscBXGxXh2rut_K3G0VBool_aJ1a4_wbfmGCIQIIeUoEdN0zV1p84ZfCTpwDbbxfnK83ia6ke_RQmoKBjrUyiciUF6jiZEfb-1Vm7aE2NWU8yhmiZ14VAq0YR3xq0OlE8FxjWpr9Lr1i-5Gy-LDOnMRM4zfvYqC_FsiOQ-wGxAxMme_-tm3B05OIsk_O82YpyxpBZYgHn7AK7xahAQMMLiL2y2viyQ","p":"7UUoo8AKof_cIhRBSwmFhTt7_e8BZ7w0uPCAcSv4DNepCoUoTSNDHuuUmgPEULmQplHwhH-wW7ACVvylSZT4JYq-qwSVr9wJoFAYQDYiJizP73eVnFkfqiv2-xwPQaFONwGGxixuz0r8j16Tpe4iMK8Hy-LYpjucvTp6RrNHgls","q":"4kfZ2710YTnCXUsgga-lZxxDIloJ55iLtRSRizRGyxVCNkH1IMoo6pf59AiPkyk1iWYTx4IS_SkelSPWNtJLnFKmgocYikILsiVVSOoI1vkq9la3FTmJkRNzPfTtFWVf0_e0Ff7dkQxr3XBEZUVS0o9-y_V3k7sMsnfuajjva78","dp":"WFk_J7Izg1z1SA9IvLsf55tdsRFU8Z6H9zE-cmWP6KBJBmzMs-Rkctf_rlWmvPRL41Jxf7TYI1vnkyJiHYMF31zJYH7FigUh5HrOfOJrVtGq350krWIWQ1Q5lAk_uQ1qRVshJxuWa0OdxXjO-6MvQfd6rLWcPFHILEHhFABfqS8","dq":"GMe3kvnfadpSb7cPe0RJ_823iGaF2Sf6fL0g5za1Xf4Y_yof9xRMgMxd4hyh5ILJyx8zoVCcVb8QC1MeXWiQQTFH7NlwlYuADmVKPq7qguhMjSeX6yoe55VStIFDCWnNob_pp9L-XqkWkux9gP2jgU2XnCxoiPQeAtlhcZ6Eka8","qi":"Rh3yHepiLVy2gxHepFp2Yi9qSCULNCySjpDy9eeegEHQMIlH5cdO6Q5UmAtQZwoexWgXhmL8hPcgKumcGq0ZG_EpStIy176-McxtkmpbycY8Bfw6rk1FH2Sfn44oIB2JxUm8yHouh6UMz3e_WeisrmotbeAmH0NtG8DyPkTSgmA"},{"kty":"RSA","kid":"u64VsIB-cxX3NHf1nYn1OtBXmWWQfZZp2BVN1rZL6XU","use":"enc","alg":"RSA-OAEP","e":"AQAB","n":"0CIIQ8dAvOfVE38owR4I03lu1oHmCJz0vSKCRWVyNXSfXwl00eH6JmyDC8sFo2h66iU8vNBauYELoxNf4yT9hXsEcDgJcf9NPW186LSttqqgZ8wSycS7Pn3YTfbzH45R5mH_1zvsKnI8Xwi2DibpOht0bVWStG-EXkAkj6YQdSR1cMQXvtBIetWP6cPx7kG-qzjze3mvtIucnKRnphbW31Bker2Ykur3_ySqXJpCxUx3TchL5-pckTfS9Na6VALIBTLR8dHPq1GJXVgQOCh6GrY7ljIY7ZbkJW2_n1SgyNT49SuxBrPWKiIJW2uIdgMtq3Fp-BFMqJJGaqQ_W2jtAw","d":"x7A_ObhMNnI_jusrkM1eLneNjiUnLRBaB7S6RBam0v7HgYkzGcO0G3V07bWl_Tfa5hdABO_qe5yCK74E-4ub6ZszkO9SsJr_4nXPp_zhxiZCrBOx2v_znmtjQroyXQ5RKbbQnhKR7c-YeJ2E_mL61ZNNyzCVBqUP3NWxvljX5WqQiwsap-RN2ZiCXKrGiC_pG59uS5NSTNqf2cgXy0eSlQqt-7T6ZAZtsCz0I6pUYfHbXa3lIHCCRtTDWoVIoaKUa01FqyBeE04V6DvU9AOZWcK670cXbzhG1kkEk5HHYrQabPrBFXtRaOrApaasGDbZDv4fRW31WnNYLuhllPcQMQ","p":"55y41df36jmE0eQmLtI1jLAq7Adw-AhweUUL-Sklf4GkzCEnJ2wVguiCni8NrFMRiCrM95ntFwT6o1neuG4St3rK5wvE_SOYbLvw2MMnjqLVr4zbbDuLJ-w8-SeqDuFRxHkR6xp8J-YwXeD5N4blceEqU36XHpChcZkzoSWCO68","q":"5gxo1-MeuxMk_-RbS85hWMyQzVOBXGpuUlDpFELB2FxjAaaEN9bDRplWfVwTL-txN24NhFZepd8Bf7NL9nAGmGtTiEWhK5jQZz_WeXA6zRLwcm1v9Hbl516baMQy1cOa5VUyrGTsjVO3Q35j8fpRFa_RK-h3U6_bdDpO3UMyFO0","dp":"TEaZvJseYz3EFxeK15qU1htiV07wDk9BMz7g_ZJmbgJ1EmDMszfuMal-8rdOSnUk7fIihFxl71HNdSRwq85cTZ6b2dFPc4pYdV7Dp69FhLztoJ3D2XYWkvRC9E7yu2nK8uhoVUPopX8yaIhhqr67K3Da7ppfDErXUEEC9swSgrM","dq":"J_XP4HBbTjOtIaYRFcHrtvkRzhjLR7pVH4dedV6DPYoOyKKcJPbxRLouA-iSjKhhKje7sVkvZ7CtGfmTIGOlQaSjBfDSZjhNOyIjp0SPcj_v9HB-GgDtPpt4c2JhUjCAH4YFH10ImiQImXjC861_mDzKIM5oq-jIPhBC0rxxXqE","qi":"exJQqZEtA7p9XxItMAip-OTQ7W6n40xexi8PrJdfEvbrk0aAqO4-ixFyqlQnkwKGQt-IIBgwxjRPwEMMMufd_iLbc0EL1QZN370hSCyqIReGa5qH0W2vvoRf4QfmIiEWumfVWTOb9isCW1nlrPnCkBgGrLxTyZKS_BWwez7eDXQ","enc":"A256CBC-HS512"}]}'
  })

  get '/' do
    erb :index, locals: { title: 'RP Client Secret Example', config: config }
  end

  get '/button/oauth' do
    scope = ['openid', 'email', 'profile']
    prompt = 'consent'
    proofs = id_partner.generate_proofs
    session[:proofs] = proofs
    session[:issuer] = params[:iss]
    redirect id_partner.get_authorization_url(params, proofs, scope, prompt, nil)
  end

  get '/button/oauth/callback' do
    token = id_partner.token(params, session[:proofs])
    userinfo = id_partner.userinfo(token['access_token'])
    content_type :json
    userinfo.to_json
  end

  get '/jwks' do
    content_type :json
    id_partner.public_jwks.to_json
  end

  run! if app_file == $0
end
