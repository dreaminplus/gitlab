# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Reports::Security::Locations::Sast do
  let(:params) do
    {
      file_path: 'src/main/App.java',
      start_line: 29,
      end_line: 31,
      class_name: 'com.gitlab.security_products.tests.App',
      method_name: 'insecureCypher'
    }
  end

  let(:mandatory_params) { %i[file_path start_line] }
  let(:expected_fingerprint) { Digest::SHA1.hexdigest('src/main/App.java:29:31') }

  it_behaves_like 'vulnerability location'
end
