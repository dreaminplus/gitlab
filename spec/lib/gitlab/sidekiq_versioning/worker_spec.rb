# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqVersioning::Worker do
  let(:worker) do
    Class.new do
      def self.name
        'DummyWorker'
      end

      # ApplicationWorker includes Gitlab::SidekiqVersioning::Worker
      include ApplicationWorker

      version 2
    end
  end

  describe '.version' do
    context 'when called with an argument' do
      it 'sets the version option' do
        worker.version 3

        expect(worker.get_sidekiq_options['version']).to eq(3)
      end
    end

    context 'when called without an argument' do
      it 'returns the version option' do
        worker.sidekiq_options version: 3

        expect(worker.version).to eq(3)
      end
    end
  end

  describe '#support_job_version?' do
    subject { worker.new }

    context 'when the job is older' do
      before do
        subject.job_version = worker.version - 1
      end

      it 'returns true' do
        expect(subject.support_job_version?).to be_truthy
      end
    end

    context 'when the job is up to date' do
      before do
        subject.job_version = worker.version
      end

      it 'returns true' do
        expect(subject.support_job_version?).to be_truthy
      end
    end

    context 'when the job is newer' do
      before do
        subject.job_version = worker.version + 1
      end

      it 'returns false' do
        expect(subject.support_job_version?).to be_falsey
      end
    end
  end
end
