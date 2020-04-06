# frozen_string_literal: true

require 'spec_helper'

describe API::API do
  include GroupAPIHelpers

  describe 'Record user last activity in after hook' do
    # It does not matter which endpoint is used because last_activity_on should
    # be updated on every request. `/groups` is used as an example
    # to represent any API endpoint
    let(:user) { create(:user, last_activity_on: Date.yesterday) }

    it 'updates the users last_activity_on date' do
      expect { get api('/groups', user) }.to change { user.reload.last_activity_on }.to(Date.today)
    end

    context 'when the the api_activity_logging feature is disabled' do
      it 'does not touch last_activity_on' do
        stub_feature_flags(api_activity_logging: false)

        expect { get api('/groups', user) }.not_to change { user.reload.last_activity_on }
      end
    end
  end

  describe 'User with only read_api scope personal access token' do
    # It does not matter which endpoint is used because this should
    # in the same way for every request. `/groups` is used as an example
    # to represent any API endpoint

    context 'when personal access token has only read_api scope' do
      let_it_be(:user) { create(:user) }
      let_it_be(:group) { create(:group) }
      let_it_be(:token) { create(:personal_access_token, user: user, scopes: [:read_api]) }

      before do
        group.add_owner(user)
      end

      it 'does authorize user for get request' do
        get api('/groups', personal_access_token: token)

        expect(response).to have_gitlab_http_status(:ok)
      end

      it 'does not authorize user for post request' do
        group_attributes = attributes_for_group_api

        post api("/groups", personal_access_token: token), params: group_attributes

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'does not authorize user for put request' do
        group_param = { name: 'Test' }

        put api("/groups/#{group.id}", personal_access_token: token), params: group_param

        expect(response).to have_gitlab_http_status(:forbidden)
      end

      it 'does not authorize user for delete request' do
        delete api("/groups/#{group.id}", personal_access_token: token)

        expect(response).to have_gitlab_http_status(:forbidden)
      end
    end
  end
end
