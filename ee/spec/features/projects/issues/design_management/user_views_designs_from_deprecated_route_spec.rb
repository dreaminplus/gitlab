# frozen_string_literal: true

require 'spec_helper'

describe 'User views issue designs from deprecated issue routes', :js do
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project_empty_repo, :public) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:design) { create(:design, :with_file, issue: issue) }

  before do
    enable_design_management
  end

  context 'navigates from the issue view on the deprecated route' do
    before do
      visit project_deprecated_issue_path(project, issue)
      click_link 'Designs'
      wait_for_requests
    end

    it 'fetches list of designs' do
      expect(page).to have_selector('.js-design-list-item', count: 1)
    end
  end

  context 'navigates directly to the design collection view on the deprecated route' do
    before do
      visit designs_project_deprecated_issue_path(project, issue)
    end

    it 'expands the sidebar' do
      expect(page).to have_selector('.layout-page.right-sidebar-expanded')
    end
  end

  context 'navigates directly to the individual design view on the deprecated route' do
    before do
      visit designs_project_deprecated_issue_path(project, issue, vueroute: design.filename)
    end

    it 'sees the design' do
      expect(page).to have_selector('.js-design-detail')
    end
  end
end
