# frozen_string_literal: true

require 'spec_helper'

describe 'CI shared runner limits' do
  let(:user) { create(:user) }
  let!(:project) { create(:project, :repository, namespace: group, shared_runners_enabled: true) }
  let(:group) { create(:group) }

  before do
    sign_in(user)
  end

  context 'when project member' do
    before do
      group.add_developer(user)
    end

    context 'without limit' do
      it 'does not display a warning message on project homepage' do
        visit_project_home
        expect_no_quota_exceeded_alert
      end

      it 'does not display a warning message on pipelines page' do
        visit_project_pipelines
        expect_no_quota_exceeded_alert
      end
    end

    context 'when limit is defined' do
      context 'when usage has reached a notification level' do
        let(:message) do
          "Group #{group.name} has 30% or less Shared Runner Pipeline minutes remaining. " \
          "Once it runs out, no new jobs or pipelines in its projects will run."
        end

        before do
          group.update(last_ci_minutes_usage_notification_level: 30, shared_runners_minutes_limit: 10)
          allow_any_instance_of(EE::Namespace).to receive(:shared_runners_remaining_minutes).and_return(2)
        end

        it 'displays a warning message on pipelines page' do
          visit_project_pipelines
          expect_quota_exceeded_alert(message)
        end

        it 'displays a warning message on project homepage' do
          visit_project_home

          expect_quota_exceeded_alert(message)
        end
      end

      context 'when limit is exceeded' do
        let(:group) { create(:group, :with_used_build_minutes_limit) }
        let(:message) do
          "Group #{group.name} has exceeded its pipeline minutes quota. " \
          "Unless you buy additional pipeline minutes, no new jobs or pipelines in its projects will run."
        end

        it 'displays a warning message on project homepage' do
          visit_project_home
          expect_quota_exceeded_alert(message)
        end

        it 'displays a warning message on pipelines page' do
          visit_project_pipelines
          expect_quota_exceeded_alert(message)
        end
      end

      context 'when limit not yet exceeded' do
        let(:group) { create(:group, :with_not_used_build_minutes_limit) }

        it 'does not display a warning message on project homepage' do
          visit_project_home
          expect_no_quota_exceeded_alert
        end

        it 'does not display a warning message on pipelines page' do
          visit_project_pipelines
          expect_no_quota_exceeded_alert
        end
      end

      context 'when minutes are not yet set' do
        let(:group) { create(:group, :with_build_minutes_limit) }

        it 'does not display a warning message on project homepage' do
          visit_project_home
          expect_no_quota_exceeded_alert
        end

        it 'does not display a warning message on pipelines page' do
          visit_project_pipelines
          expect_no_quota_exceeded_alert
        end
      end
    end
  end

  context 'when not a project member' do
    let(:group) { create(:group, :with_used_build_minutes_limit) }

    context 'when limit is defined and limit is exceeded' do
      it 'does not display a warning message on project homepage' do
        visit_project_home
        expect_no_quota_exceeded_alert
      end

      it 'does not display a warning message on pipelines page' do
        visit_project_pipelines
        expect_no_quota_exceeded_alert
      end
    end
  end

  def visit_project_home
    visit project_path(project)
  end

  def visit_project_pipelines
    visit project_pipelines_path(project)
  end

  def expect_quota_exceeded_alert(message = nil)
    expect(page).to have_selector('.shared-runner-quota-message', count: 1)

    if message
      element = page.find('.shared-runner-quota-message')
      expect(element).to have_content(message)
    end
  end

  def expect_no_quota_exceeded_alert
    expect(page).not_to have_selector('.shared-runner-quota-message')
  end
end
