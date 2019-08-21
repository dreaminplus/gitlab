# frozen_string_literal: true

module EE
  module LoginHelpers
    def configure_group_saml_mock_auth(uid:)
      name = 'My name'
      email = 'name@example.com'
      response_object = { document: saml_xml(File.read('spec/fixtures/authentication/saml_response.xml')) }

      OmniAuth.config.mock_auth[:group_saml] = OmniAuth::AuthHash.new({
        provider: :group_saml,
        uid: uid,
        info: { name: name, email: email },
        extra: {
          raw_info: { info: { name: name, email: email } },
          response_object: response_object
        }
      })
    end

    def mock_group_saml(uid:)
      allow(Devise).to receive(:omniauth_providers).and_return(%i(group_saml))
      allow_any_instance_of(::Gitlab::Auth::Saml::OriginValidator).to receive(:gitlab_initiated?).and_return(true)
      configure_group_saml_mock_auth(uid: uid)
      stub_omniauth_provider(:group_saml)
    end
  end
end
