# frozen_string_literal: true

require 'spec_helper'

describe DesignManagement::NewVersionWorker do
  # TODO a number of these tests are being temporarily skipped unless run in EE,
  # as we are in the process of moving Design Management to FOSS in 13.0
  # in steps. In the current step the services have not yet been moved.
  #
  # See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283.
  describe '#perform' do
    let(:worker) { described_class.new }

    context 'the id is wrong or out-of-date' do
      let(:version_id) { -1 }

      it 'does not create system notes' do
        skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

        expect(SystemNoteService).not_to receive(:design_version_added)

        worker.perform(version_id)
      end

      it 'does not invoke GenerateImageVersionsService' do
        skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

        expect(DesignManagement::GenerateImageVersionsService).not_to receive(:new)

        worker.perform(version_id)
      end

      it 'logs the reason for this failure' do
        expect(Sidekiq.logger).to receive(:warn)
          .with(an_instance_of(ActiveRecord::RecordNotFound))

        worker.perform(version_id)
      end
    end

    context 'the version id is valid' do
      let_it_be(:version) { create(:design_version, :with_lfs_file, designs_count: 2) }

      it 'creates a system note' do
        skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

        expect { worker.perform(version.id) }.to change { Note.system.count }.by(1)
      end

      it 'invokes GenerateImageVersionsService' do
        skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

        expect_next_instance_of(DesignManagement::GenerateImageVersionsService) do |service|
          expect(service).to receive(:execute)
        end

        worker.perform(version.id)
      end

      it 'does not log anything' do
        skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

        expect(Sidekiq.logger).not_to receive(:warn)

        worker.perform(version.id)
      end
    end

    context 'the version includes multiple types of action' do
      let_it_be(:version) do
        create(:design_version, :with_lfs_file,
               created_designs: create_list(:design, 1, :with_lfs_file),
               modified_designs: create_list(:design, 1))
      end

      it 'creates two system notes' do
        skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

        expect { worker.perform(version.id) }.to change { Note.system.count }.by(2)
      end

      it 'calls design_version_added' do
        skip 'See https://gitlab.com/gitlab-org/gitlab/-/issues/212566#note_327724283' unless Gitlab.ee?

        expect(SystemNoteService).to receive(:design_version_added).with(version)

        worker.perform(version.id)
      end
    end
  end
end
