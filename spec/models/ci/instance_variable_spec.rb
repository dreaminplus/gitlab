# frozen_string_literal: true

require 'spec_helper'

describe Ci::InstanceVariable do
  subject { build(:ci_instance_variable) }

  it_behaves_like "CI variable"

  it { is_expected.to include_module(Ci::Maskable) }
  it { is_expected.to validate_uniqueness_of(:key).with_message(/\(\w+\) has already been taken/) }

  describe '.unprotected' do
    subject { described_class.unprotected }

    context 'when variable is protected' do
      before do
        create(:ci_instance_variable, :protected)
      end

      it 'returns nothing' do
        is_expected.to be_empty
      end
    end

    context 'when variable is not protected' do
      let(:variable) { create(:ci_instance_variable, protected: false) }

      it 'returns the variable' do
        is_expected.to contain_exactly(variable)
      end
    end
  end
end
