# frozen_string_literal: true

require 'spec_helper'

describe Vulnerabilities::Feedback do
  it {
    is_expected.to(
      define_enum_for(:feedback_type)
      .with_values(dismissal: 0, issue: 1, merge_request: 2)
      .with_prefix(:for)
    )
  }
  it { is_expected.to define_enum_for(:category) }

  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to belong_to(:author).class_name('User') }
    it { is_expected.to belong_to(:comment_author).class_name('User') }
    it { is_expected.to belong_to(:issue) }
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:pipeline).class_name('Ci::Pipeline').with_foreign_key('pipeline_id') }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:author) }
    it { is_expected.to validate_presence_of(:feedback_type) }
    it { is_expected.to validate_presence_of(:category) }
    it { is_expected.to validate_presence_of(:project_fingerprint) }

    context 'pipeline is nil' do
      let(:feedback) { build(:vulnerability_feedback, pipeline_id: nil) }

      it 'is valid' do
        expect(feedback).to be_valid
      end
    end

    context 'pipeline has the same project_id' do
      let(:feedback) { build(:vulnerability_feedback) }

      it 'is valid' do
        expect(feedback.project_id).to eq(feedback.pipeline.project_id)
        expect(feedback).to be_valid
      end
    end

    context 'pipeline_id does not exist' do
      let(:feedback) { build(:vulnerability_feedback, pipeline_id: -100) }

      it 'is invalid' do
        expect(feedback.project_id).not_to eq(feedback.pipeline_id)
        expect(feedback).not_to be_valid
      end
    end
    context 'pipeline has a different project_id' do
      let(:project) { create(:project) }
      let(:pipeline) { create(:ci_pipeline, project: create(:project)) }
      let(:feedback) { build(:vulnerability_feedback, project: project, pipeline: pipeline) }

      it 'is invalid' do
        expect(feedback.project_id).not_to eq(feedback.pipeline_id)
        expect(feedback).not_to be_valid
      end
    end

    context 'comment is set' do
      let(:feedback) { build(:vulnerability_feedback, comment: 'a comment' ) }

      it 'validates presence of comment_timestamp' do
        expect(feedback).to validate_presence_of(:comment_timestamp)
      end

      it 'validates presence of comment_author' do
        expect(feedback).to validate_presence_of(:comment_author)
      end
    end
  end

  describe '.with_category' do
    it 'filters by category' do
      described_class.categories.each do |category, _|
        create(:vulnerability_feedback, category: category)
      end

      expect(described_class.count).to eq described_class.categories.length

      expected, _ = described_class.categories.first

      feedback = described_class.with_category(expected)

      expect(feedback.length).to eq 1
      expect(feedback.first.category).to eq expected
    end
  end

  describe '.with_feedback_type' do
    it 'filters by feedback_type' do
      create(:vulnerability_feedback, :dismissal)
      create(:vulnerability_feedback, :issue)
      create(:vulnerability_feedback, :merge_request)

      feedback = described_class.with_feedback_type('issue')

      expect(feedback.length).to eq 1
      expect(feedback.first.feedback_type).to eq 'issue'
    end
  end

  # TODO remove once filtered data has been cleaned
  describe '::only_valid_feedback' do
    let(:project) { create(:project) }
    let(:pipeline) { create(:ci_pipeline, project: project) }

    let!(:feedback) { create(:vulnerability_feedback, :dismissal, :sast, project: project, pipeline: pipeline) }
    let!(:invalid_feedback) do
      feedback = build(:vulnerability_feedback, project: project, pipeline: create(:ci_pipeline))

      feedback.save(validate: false)
    end

    it 'filters out invalid feedback' do
      feedback_records = described_class.only_valid_feedback

      expect(feedback_records.length).to eq 1
      expect(feedback_records.first).to eq feedback
    end
  end

  describe '#has_comment?' do
    let(:feedback) { build(:vulnerability_feedback, comment: comment, comment_author: comment_author) }
    let(:comment) { 'a comment' }
    let(:comment_author) { build(:user) }

    subject { feedback.has_comment? }

    context 'comment and comment_author are set' do
      it { is_expected.to be_truthy }
    end

    context 'comment is set and comment_author is not' do
      let(:comment_author) { nil }

      it { is_expected.to be_falsy }
    end

    context 'comment and comment_author are not set' do
      let(:comment) { nil }
      let(:comment_author) { nil }

      it { is_expected.to be_falsy }
    end
  end

  describe '#find_or_init_for' do
    let(:group) { create(:group) }
    let(:project) { create(:project, :public, :repository, namespace: group) }
    let(:user) { create(:user) }
    let(:pipeline) { create(:ci_pipeline, project: project) }

    let(:feedback_params) do
      {
        feedback_type: 'dismissal', pipeline_id: pipeline.id, category: 'sast',
        project_fingerprint: '418291a26024a1445b23fe64de9380cdcdfd1fa8',
        author: user,
        vulnerability_data: {
          category: 'sast',
          priority: 'Low', line: '41',
          file: 'subdir/src/main/java/com/gitlab/security_products/tests/App.java',
          cve: '818bf5dacb291e15d9e6dc3c5ac32178:PREDICTABLE_RANDOM',
          name: 'Predictable pseudorandom number generator',
          description: 'Description of Predictable pseudorandom number generator',
          tool: 'find_sec_bugs'
        }
      }
    end

    context 'when params are valid' do
      subject(:feedback) { described_class.find_or_init_for(feedback_params) }

      before do
        feedback.project = project
      end

      it 'inits the feedback' do
        is_expected.to be_new_record
      end

      it 'finds the existing feedback' do
        feedback.save!

        existing_feedback = described_class.find_or_init_for(feedback_params)

        expect(existing_feedback).to eq(feedback)
      end

      context 'when attempting to save duplicate' do
        it 'raises ActiveRecord::RecordInvalid' do
          duplicate = described_class.find_or_init_for(feedback_params)
          duplicate.project = project

          feedback.save!

          expect { duplicate.save! }.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when params are invalid' do
      it 'raises ArgumentError when given a bad feedback_type value' do
        feedback_params[:feedback_type] = 'foo'

        expect { described_class.find_or_init_for(feedback_params) }.to raise_error(ArgumentError, /feedback_type/)
      end

      it 'raises ArgumentError when given a bad category value' do
        feedback_params[:category] = 'foo'

        expect { described_class.find_or_init_for(feedback_params) }.to raise_error(ArgumentError, /category/)
      end
    end
  end
end
