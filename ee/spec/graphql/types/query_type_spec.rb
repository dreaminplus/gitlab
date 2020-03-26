# frozen_string_literal: true

require 'spec_helper'

describe GitlabSchema.types['Query'] do
  specify do
    expect(described_class).to have_graphql_fields(
      :design_management,
      :geo_node,
      :vulnerabilities
    ).at_least
  end

  describe 'vulnerabilities' do
    let_it_be(:project) { create(:project) }
    let_it_be(:user) { create(:user, security_dashboard_projects: [project]) }

    let_it_be(:vulnerability) do
      create(:vulnerability, :detected, :critical, project: project, title: 'A terrible one!')
    end

    let_it_be(:query) do
      %(
        query {
          vulnerabilities {
            nodes {
              title
              severity
              state
            }
          }
        }
      )
    end

    before do
      project.add_developer(user)
    end

    subject { GitlabSchema.execute(query, context: { current_user: user }).as_json }

    context 'when first_class_vulnerabilities is disabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: false)
      end

      it 'is null' do
        vulnerabilities = subject.dig('data', 'vulnerabilities')

        expect(vulnerabilities).to be_nil
      end
    end

    context 'when first_class_vulnerabilities is enabled' do
      before do
        stub_feature_flags(first_class_vulnerabilities: true)
        stub_licensed_features(security_dashboard: true)
      end

      it "returns vulnerabilities for projects on the current user's instance security dashboard" do
        vulnerabilities = subject.dig('data', 'vulnerabilities', 'nodes')

        expect(vulnerabilities.count).to be(1)
        expect(vulnerabilities.first['title']).to eq('A terrible one!')
        expect(vulnerabilities.first['state']).to eq('DETECTED')
        expect(vulnerabilities.first['severity']).to eq('CRITICAL')
      end
    end
  end
end
