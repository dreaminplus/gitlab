# frozen_string_literal: true

require 'spec_helper'

RSpec.describe WikiHelper do
  describe '#breadcrumb' do
    context 'when the page is at the root level' do
      it 'returns the capitalized page name' do
        slug = 'page-name'

        expect(helper.breadcrumb(slug)).to eq('Page name')
      end
    end

    context 'when the page is inside a directory' do
      it 'returns the capitalized name of each directory and of the page itself' do
        slug = 'dir_1/page-name'

        expect(helper.breadcrumb(slug)).to eq('Dir_1 / Page name')
      end
    end
  end

  describe '#wiki_sort_controls' do
    let(:wiki) { create(:project_wiki) }
    let(:wiki_link) { helper.wiki_sort_controls(wiki, sort, direction) }
    let(:classes) { "btn btn-default has-tooltip reverse-sort-btn qa-reverse-sort rspec-reverse-sort" }

    def expected_link(sort, direction, icon_class)
      path = "/#{wiki.project.full_path}/-/wikis/pages?direction=#{direction}&sort=#{sort}"

      helper.link_to(path, type: 'button', class: classes, title: 'Sort direction') do
        helper.sprite_icon("sort-#{icon_class}", size: 16)
      end
    end

    context 'initial call' do
      let(:sort) { nil }
      let(:direction) { nil }

      it 'renders with default values' do
        expect(wiki_link).to eq(expected_link('title', 'desc', 'lowest'))
      end
    end

    context 'sort by title' do
      let(:sort) { 'title' }
      let(:direction) { 'asc' }

      it 'renders a link with opposite direction' do
        expect(wiki_link).to eq(expected_link('title', 'desc', 'lowest'))
      end
    end

    context 'sort by created_at' do
      let(:sort) { 'created_at' }
      let(:direction) { 'desc' }

      it 'renders a link with opposite direction' do
        expect(wiki_link).to eq(expected_link('created_at', 'asc', 'highest'))
      end
    end
  end

  describe '#wiki_sort_title' do
    it 'returns a title corresponding to a key' do
      expect(helper.wiki_sort_title('created_at')).to eq('Created date')
      expect(helper.wiki_sort_title('title')).to eq('Title')
    end

    it 'defaults to Title if a key is unknown' do
      expect(helper.wiki_sort_title('unknown')).to eq('Title')
    end
  end

  describe '#wiki_page_tracking_payload' do
    let_it_be(:page) { create(:wiki_page, title: 'path/to/page 💩', content: '💩', format: :markdown) }

    subject { helper.wiki_page_tracking_payload(page) }

    it 'returns the tracking payload' do
      expect(subject).to eq(
        'wiki-format'               => :markdown,
        'wiki-title-size'           => 9,
        'wiki-content-size'         => 4,
        'wiki-directory-nest-level' => 2
      )
    end

    it 'returns a nest level of zero for toplevel files' do
      expect(page).to receive(:path).and_return('page')
      expect(subject).to include('wiki-directory-nest-level' => 0)
    end
  end
end
