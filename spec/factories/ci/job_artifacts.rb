<<<<<<< HEAD
include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :ci_job_artifact, class: Ci::JobArtifact do
    job factory: :ci_build
    file_type :archive

    trait :remote_store do
      file_store JobArtifactUploader::REMOTE_STORE
    end

    after :build do |artifact|
      artifact.project ||= artifact.job.project
    end

    trait :archive do
      file_type :archive

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
      end
    end

    trait :metadata do
      file_type :metadata

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'), 'application/x-gzip')
      end
    end
  end
end
||||||| merged common ancestors
=======
include ActionDispatch::TestProcess

FactoryGirl.define do
  factory :ci_job_artifact, class: Ci::JobArtifact do
    job factory: :ci_build
    file_type :archive

    after :build do |artifact|
      artifact.project ||= artifact.job.project
    end

    trait :archive do
      file_type :archive

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/ci_build_artifacts.zip'), 'application/zip')
      end
    end

    trait :metadata do
      file_type :metadata

      after(:build) do |artifact, _|
        artifact.file = fixture_file_upload(
          Rails.root.join('spec/fixtures/ci_build_artifacts_metadata.gz'), 'application/x-gzip')
      end
    end
  end
end
>>>>>>> ce/10-3-stable
