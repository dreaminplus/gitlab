# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::GitAccessDesign do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { project.owner }
  let(:protocol) { 'web' }
  let(:actor) { :geo }

  subject(:access) do
    described_class.new(actor, project, protocol, authentication_abilities: [:read_project, :download_code, :push_code])
  end

  describe "#check" do
    subject { access.check('git-receive-pack', ::Gitlab::GitAccess::ANY) }

    before do
      enable_design_management
    end

    context "when the protocol is not web" do
      let(:protocol) { 'https' }

      it { is_expected.to be_a(::Gitlab::GitAccessResult::Success) }
    end

    context 'http protocol' do
      let(:protocol) { 'http' }

      it { is_expected.to be_a(::Gitlab::GitAccessResult::Success) }
    end
  end
end
