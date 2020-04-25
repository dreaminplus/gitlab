# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project navbar' do
  include NavbarStructureHelper
  include WaitForRequests

  include_context 'project navbar structure'

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  before do
    stub_licensed_features(service_desk: false)

    project.add_maintainer(user)
    sign_in(user)

    if ::Gitlab.ee?
      insert_after_nav_item(
        _('Operations'),
        new_nav_item: {
          nav_item: _('Packages & Registries'),
          nav_sub_items: [_('Package Registry')]
        }
      )
    end
  end

  it_behaves_like 'verified navigation bar' do
    before do
      visit project_path(project)
    end
  end

  context 'when value stream is available' do
    before do
      visit project_path(project)
    end

    it 'redirects to value stream when Analytics item is clicked' do
      page.within('.sidebar-top-level-items') do
        find('[data-qa-selector=analytics_anchor]').click
      end

      wait_for_requests

      expect(page).to have_current_path(project_cycle_analytics_path(project))
    end
  end

  context 'when pages are available' do
    before do
      stub_config(pages: { enabled: true })

      insert_after_sub_nav_item(
        _('Operations'),
        within: _('Settings'),
        new_sub_nav_item_name: _('Pages')
      )

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end

  context 'when container registry is available' do
    before do
      stub_config(registry: { enabled: true })

      if ::Gitlab.ee?
        insert_after_sub_nav_item(
          _('Package Registry'),
          within: _('Packages & Registries'),
          new_sub_nav_item_name: _('Container Registry')
        )
      else
        insert_after_nav_item(
          _('Operations'),
          new_nav_item: {
            nav_item: _('Packages & Registries'),
            nav_sub_items: [_('Container Registry')]
          }
        )
      end

      visit project_path(project)
    end

    it_behaves_like 'verified navigation bar'
  end
end
