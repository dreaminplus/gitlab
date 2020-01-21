# frozen_string_literal: true

class IssueAssignee < ApplicationRecord
  belongs_to :issue
  belongs_to :assignee, class_name: "User", foreign_key: :user_id

  validates_uniqueness_of :assignee, scope: :issue_id
end

IssueAssignee.prepend_if_ee('EE::IssueAssignee')
