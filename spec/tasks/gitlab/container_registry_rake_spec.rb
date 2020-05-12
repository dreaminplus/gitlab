# frozen_string_literal: true

require 'rake_helper'

def stub_registry_info(output)
  allow_any_instance_of(ContainerRegistry::Client)
    .to receive(:registry_info)
    .and_return(output)
end

describe 'gitlab:container_registry namespace rake tasks' do
  let_it_be(:application_settings) { create(:application_setting) }

  before :all do
    Rake.application.rake_require 'tasks/gitlab/container_registry'
  end

  describe 'configure' do
    context 'when unabled to detect the container registry type' do
      it 'aborts and display a help message' do
        stub_registry_info(vendor: nil, version: nil, features: nil)

        expect { run_rake_task('gitlab:container_registry:configure') }
          .to raise_error 'Failed to detect registry vendor'
      end
    end

    context 'when able to detect the container registry type' do
      context 'when using the GitLab container registry' do
        it 'updates application settings accordingly' do
          stub_registry_info(vendor: 'gitlab', version: '2.9.1-gitlab', features: %w[a,b,c])

          run_rake_task('gitlab:container_registry:configure')

          application_settings.reload
          expect(application_settings.container_registry_vendor).to eq('gitlab')
          expect(application_settings.container_registry_version).to eq('2.9.1-gitlab')
          expect(application_settings.container_registry_features).to eq(%w[a,b,c])
        end
      end

      context 'when using a third-party container registry' do
        it 'updates application settings accordingly' do
          stub_registry_info(vendor: 'other', version: nil, features: nil)

          run_rake_task('gitlab:container_registry:configure')

          application_settings.reload
          expect(application_settings.container_registry_vendor).to eq('other')
          expect(application_settings.container_registry_version).to be_empty
          expect(application_settings.container_registry_features).to be_empty
        end
      end
    end
  end
end
