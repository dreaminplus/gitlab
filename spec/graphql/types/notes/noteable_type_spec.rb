# frozen_string_literal: true
require 'spec_helper'

describe Types::Notes::NoteableType do
  specify { expect(described_class).to have_graphql_fields(:notes, :discussions) }

  describe ".resolve_type" do
    it 'knows the correct type for objects' do
      expect(described_class.resolve_type(build(:issue), {})).to eq(Types::IssueType)
      expect(described_class.resolve_type(build(:merge_request), {})).to eq(Types::MergeRequestType)
      expect(described_class.resolve_type(build(:snippet), {})).to eq(Types::SnippetType)
      expect(described_class.resolve_type(build(:design), {})).to eq(Types::DesignManagement::DesignType)
    end
  end
end
