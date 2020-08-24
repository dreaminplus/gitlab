# frozen_string_literal: true

RSpec.shared_examples 'handling all upload parameters conditions' do
  context 'one root parameter' do
    include_context 'with one temporary file for multipart'

    let(:rewritten_fields) { { 'file' => path_for(uploaded_file) } }
    let(:params) { upload_parameters_for(filepath: uploaded_filepath, key: 'file', filename: filename, remote_id: remote_id) }

    it 'builds an UploadedFile' do
      expect_uploaded_files(filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w(file))

      subject
    end
  end

  context 'two root parameters' do
    include_context 'with two temporary files for multipart'

    let(:rewritten_fields) { { 'file1' => path_for(uploaded_file), 'file2' => path_for(uploaded_file2) } }
    let(:params) do
      upload_parameters_for(filepath: uploaded_filepath, key: 'file1', filename: filename, remote_id: remote_id).merge(
        upload_parameters_for(filepath: uploaded_filepath2, key: 'file2', filename: filename2, remote_id: remote_id2)
      )
    end

    it 'builds UploadedFiles' do
      expect_uploaded_files([
        { filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w(file1) },
        { filepath: uploaded_filepath2, original_filename: filename2, remote_id: remote_id2, size: uploaded_file2.size, params_path: %w(file2) }
      ])

      subject
    end
  end

  context 'one nested parameter' do
    include_context 'with one temporary file for multipart'

    let(:rewritten_fields) { { 'user[avatar]' => path_for(uploaded_file) } }
    let(:params) { { 'user' => { 'avatar' => upload_parameters_for(filepath: uploaded_filepath, filename: filename, remote_id: remote_id) } } }

    it 'builds an UploadedFile' do
      expect_uploaded_files(filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w(user avatar))

      subject
    end
  end

  context 'two nested parameters' do
    include_context 'with two temporary files for multipart'

    let(:rewritten_fields) { { 'user[avatar]' => path_for(uploaded_file), 'user[screenshot]' => path_for(uploaded_file2) } }
    let(:params) do
      {
        'user' => {
          'avatar' => upload_parameters_for(filepath: uploaded_filepath, filename: filename, remote_id: remote_id),
          'screenshot' => upload_parameters_for(filepath: uploaded_filepath2, filename: filename2, remote_id: remote_id2)
        }
      }
    end

    it 'builds UploadedFiles' do
      expect_uploaded_files([
        { filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w(user avatar) },
        { filepath: uploaded_filepath2, original_filename: filename2, remote_id: remote_id2, size: uploaded_file2.size, params_path: %w(user screenshot) }
      ])

      subject
    end
  end

  context 'one deeply nested parameter' do
    include_context 'with one temporary file for multipart'

    let(:rewritten_fields) { { 'user[avatar][bananas]' => path_for(uploaded_file) } }
    let(:params) { { 'user' => { 'avatar' => { 'bananas' => upload_parameters_for(filepath: uploaded_filepath, filename: filename, remote_id: remote_id) } } } }

    it 'builds an UploadedFile' do
      expect_uploaded_files(filepath: uploaded_file, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w(user avatar bananas))

      subject
    end
  end

  context 'two deeply nested parameters' do
    include_context 'with two temporary files for multipart'

    let(:rewritten_fields) { { 'user[avatar][bananas]' => path_for(uploaded_file), 'user[friend][ananas]' => path_for(uploaded_file2) } }
    let(:params) do
      {
        'user' => {
          'avatar' => {
            'bananas' => upload_parameters_for(filepath: uploaded_filepath, filename: filename, remote_id: remote_id)
          },
          'friend' => {
            'ananas' => upload_parameters_for(filepath: uploaded_filepath2, filename: filename2, remote_id: remote_id2)
          }
        }
      }
    end

    it 'builds UploadedFiles' do
      expect_uploaded_files([
        { filepath: uploaded_file, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w(user avatar bananas) },
        { filepath: uploaded_file2, original_filename: filename2, remote_id: remote_id2, size: uploaded_file2.size, params_path: %w(user friend ananas) }
      ])

      subject
    end
  end

  context 'three parameters nested at different levels' do
    include_context 'with three temporary files for multipart'

    let(:rewritten_fields) do
      {
        'file' => path_for(uploaded_file),
        'user[avatar]' => path_for(uploaded_file2),
        'user[friend][avatar]' => path_for(uploaded_file3)
      }
    end

    let(:params) do
      upload_parameters_for(filepath: uploaded_filepath, filename: filename, key: 'file', remote_id: remote_id).merge(
        'user' => {
          'avatar' => upload_parameters_for(filepath: uploaded_filepath2, filename: filename2, remote_id: remote_id2),
          'friend' => {
            'avatar' => upload_parameters_for(filepath: uploaded_filepath3, filename: filename3, remote_id: remote_id3)
          }
        }
      )
    end

    it 'builds UploadedFiles' do
      expect_uploaded_files([
        { filepath: uploaded_filepath, original_filename: filename, remote_id: remote_id, size: uploaded_file.size, params_path: %w(file) },
        { filepath: uploaded_filepath2, original_filename: filename2, remote_id: remote_id2, size: uploaded_file2.size, params_path: %w(user avatar) },
        { filepath: uploaded_filepath3, original_filename: filename3, remote_id: remote_id3, size: uploaded_file3.size, params_path: %w(user friend avatar) }
      ])

      subject
    end
  end
end

RSpec.shared_examples 'handling uploaded file located in tmp sub dir' do |path_in_tmp_sub_dir: ''|
  include_context 'with one temporary file for multipart', within_tmp_sub_dir: true, path_in_tmp_sub_dir: path_in_tmp_sub_dir
  include_context 'with Dir.tmpdir stubbed to a tmp sub dir'

  let(:rewritten_fields) { { 'file' => path_for(uploaded_file) } }
  let(:params) { upload_parameters_for(filepath: uploaded_file.path, key: 'file', filename: filename) }

  it 'builds an UploadedFile' do
    expect_uploaded_files(filepath: uploaded_filepath, original_filename: filename, size: uploaded_file.size, params_path: %w(file))

    subject
  end
end

RSpec.shared_examples 'raising a bad request for insecure path used' do
  include_context 'with one temporary file for multipart', within_tmp_sub_dir: true
  include_context 'with Dir.tmpdir stubbed to a tmp sub dir'

  let!(:rewritten_fields) { { 'file' => path_for(uploaded_file) } }
  let!(:params) { upload_parameters_for(filepath: uploaded_filepath, key: 'file') }

  it 'returns an error' do
    result = subject

    expect(result[0]).to eq(400)
    expect(result[2]).to include('insecure path used')
  end
end
