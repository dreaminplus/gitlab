# frozen_string_literal: true

require 'spec_helper'

describe Types::Projects::ServiceType do
  it { expect(described_class).to have_graphql_fields(:type, :active) }

  describe ".resolve_type" do
    it 'resolves the corresponding type for objects' do
      expect(described_class.resolve_type(build(:jira_service), {})).to eq(Types::Projects::Services::JiraServiceType)
      expect(described_class.resolve_type(build(:service), {})).to eq(Types::Projects::Services::BaseServiceType)
      expect(described_class.resolve_type(build(:alerts_service), {})).to eq(Types::Projects::Services::BaseServiceType)
      expect(described_class.resolve_type(build(:custom_issue_tracker_service), {})).to eq(Types::Projects::Services::BaseServiceType)
    end
  end
end
