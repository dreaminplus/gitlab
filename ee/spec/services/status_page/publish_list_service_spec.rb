# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::PublishListService do
  let_it_be(:project, refind: true) { create(:project) }
  let(:issues) { [instance_double(Issue)] }
  let(:key) { StatusPage::Storage.list_path }
  let(:content) { [{ some: :content }] }

  let(:service) { described_class.new(project: project) }

  subject(:result) { service.execute(issues) }

  describe '#execute' do
    before do
      allow(serializer).to receive(:represent_list).with(issues)
        .and_return(content)
    end

    include_examples 'publish incidents'
  end
end
