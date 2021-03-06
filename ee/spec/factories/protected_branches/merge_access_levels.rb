# frozen_string_literal: true

FactoryBot.define do
  factory :protected_branch_merge_access_level, class: 'ProtectedBranch::MergeAccessLevel' do
    user { nil }
    group { nil }
    protected_branch
    access_level { Gitlab::Access::DEVELOPER }
  end
end
