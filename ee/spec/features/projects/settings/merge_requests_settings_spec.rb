require 'spec_helper'

describe 'Project settings > [EE] Merge Requests', :js do
  include GitlabRoutingHelper

  let(:user) { create(:user) }
  let(:project) { create(:project, approvals_before_merge: 1) }
  let(:group) { create(:group) }
  let(:group_member) { create(:user) }
  let(:non_member) { create(:user) }
  let!(:config_selector) { '.js-approval-rules' }
  let!(:modal_selector) { '#project-settings-approvals-create-modal' }

  def open_modal
    page.execute_script "document.querySelector('#{config_selector}').scrollIntoView()"
    within(config_selector) do
      click_on('Edit')
    end
  end

  def open_approver_select
    within(modal_selector) do
      find('.select2-input').click
    end
    wait_for_requests
  end

  def close_approver_select
    within(modal_selector) do
      find('.select2-input').send_keys :escape
    end
  end

  def remove_approver(name)
    el = page.find("#{modal_selector} .content-list li", text: /#{name}/i)
    el.find('button').click
  end

  def expect_avatar(container, users)
    users = Array(users)

    members = container.all('.js-members img.avatar').map do |member|
      member['alt']
    end

    users.each do |user|
      expect(members).to include(user.name)
    end

    expect(members.size).to eq(users.size)
  end

  before do
    sign_in(user)
    project.add_maintainer(user)
    group.add_developer(user)
    group.add_developer(group_member)
  end

  it 'adds approver' do
    visit edit_project_path(project)

    open_modal
    open_approver_select

    expect(find('.select2-results')).to have_content(user.name)
    expect(find('.select2-results')).not_to have_content(non_member.name)

    find('.user-result', text: user.name).click
    close_approver_select
    click_button 'Add'

    expect(find('.content-list')).to have_content(user.name)

    open_approver_select

    expect(find('.select2-results')).not_to have_content(user.name)

    close_approver_select
    click_button 'Update approvers'
    wait_for_requests

    expect_avatar(find('.js-members'), user)
  end

  it 'adds approver group' do
    visit edit_project_path(project)

    open_modal
    open_approver_select

    expect(find('.select2-results')).to have_content(group.name)

    find('.user-result', text: group.name).click
    close_approver_select
    click_button 'Add'

    expect(find('.content-list')).to have_content(group.name)

    click_button 'Update approvers'
    wait_for_requests

    expect_avatar(find('.js-members'), group.users)
  end

  context 'with an approver group' do
    let(:non_group_approver) { create(:user) }
    let!(:rule) { create(:approval_project_rule, project: project, groups: [group], users: [non_group_approver]) }

    before do
      project.add_developer(non_group_approver)
    end

    it 'removes approver group' do
      visit edit_project_path(project)

      expect_avatar(find('.js-members'), rule.approvers)

      open_modal
      remove_approver(group.name)
      click_button "Update approvers"
      wait_for_requests

      expect_avatar(find('.js-members'), [non_group_approver])
    end
  end

  context 'issuable default templates feature not available' do
    before do
      stub_licensed_features(issuable_default_templates: false)
    end

    it 'input to configure merge request template is not shown' do
      visit edit_project_path(project)

      expect(page).not_to have_selector('#project_merge_requests_template')
    end
  end

  context 'issuable default templates feature is available' do
    before do
      stub_licensed_features(issuable_default_templates: true)
    end

    it 'input to configure merge request template is not shown' do
      visit edit_project_path(project)

      expect(page).to have_selector('#project_merge_requests_template')
    end
  end
end
