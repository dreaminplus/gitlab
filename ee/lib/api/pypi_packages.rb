# frozen_string_literal: true

# PyPI Package Manager Client API
#
# These API endpoints are not meant to be consumed directly by users. They are
# called by the PyPI package manager client when users run commands
# like `pip install` or `twine upload`.
module API
  class PypiPackages < Grape::API::Instance
    helpers ::API::Helpers::PackagesManagerClientsHelpers
    helpers ::API::Helpers::RelatedResourcesHelpers
    helpers ::API::Helpers::Packages::BasicAuthHelpers
    include ::API::Helpers::Packages::BasicAuthHelpers::Constants

    default_format :json

    rescue_from ArgumentError do |e|
      render_api_error!(e.message, 400)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      render_api_error!(e.message, 400)
    end

    helpers do
      def packages_finder(project = authorized_user_project)
        project
          .packages
          .pypi
          .has_version
          .processed
      end

      def find_package_versions
        packages = packages_finder
          .with_name(params[:package_name])

        not_found!('Package') if packages.empty?

        packages
      end
    end

    before do
      require_packages_enabled!
    end

    params do
      requires :id, type: Integer, desc: 'The ID of a project'
    end

    resource :projects, requirements: API::NAMESPACE_OR_PROJECT_REQUIREMENTS do
      before do
        unauthorized_user_project!
      end

      namespace ':id/packages/pypi' do
        desc 'The PyPi package download endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
        end

        params do
          requires :file_identifier, type: String, desc: 'The PyPi package file identifier', file_path: true
          requires :sha256, type: String, desc: 'The PyPi package sha256 check sum'
        end

        route_setting :authentication, deploy_token_allowed: true
        get 'files/:sha256/*file_identifier' do
          project = unauthorized_user_project!

          filename = "#{params[:file_identifier]}.#{params[:format]}"
          package = packages_finder(project).by_file_name_and_sha256(filename, params[:sha256])
          package_file = ::Packages::PackageFileFinder.new(package, filename, with_file_name_like: false).execute

          present_carrierwave_file!(package_file.file, supports_direct_download: true)
        end

        desc 'The PyPi Simple Endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
        end

        params do
          requires :package_name, type: String, file_path: true, desc: 'The PyPi package name'
        end

        # An Api entry point but returns an HTML file instead of JSON.
        # PyPi simple API returns the package descriptor as a simple HTML file.
        route_setting :authentication, deploy_token_allowed: true
        get 'simple/*package_name', format: :txt do
          authorize_read_package!(authorized_user_project)

          packages = find_package_versions
          presenter = ::Packages::Pypi::PackagePresenter.new(packages, authorized_user_project)

          # Adjusts grape output format
          # to be HTML
          content_type "text/html; charset=utf-8"
          env['api.format'] = :binary

          body presenter.body
        end

        desc 'The PyPi Package upload endpoint' do
          detail 'This feature was introduced in GitLab 12.10'
        end

        params do
          requires :content, type: ::API::Validations::Types::WorkhorseFile, desc: 'The package file to be published (generated by Multipart middleware)'
          requires :requires_python, type: String
          requires :name, type: String
          requires :version, type: String
          optional :md5_digest, type: String
          optional :sha256_digest, type: String
        end

        route_setting :authentication, deploy_token_allowed: true
        post do
          authorize_upload!(authorized_user_project)

          ::Packages::Pypi::CreatePackageService
            .new(authorized_user_project, current_user, declared_params)
            .execute

          created!
        rescue ObjectStorage::RemoteStoreError => e
          Gitlab::ErrorTracking.track_exception(e, extra: { file_name: params[:name], project_id: authorized_user_project.id })

          forbidden!
        end

        route_setting :authentication, deploy_token_allowed: true
        post 'authorize' do
          authorize_workhorse!(subject: authorized_user_project, has_length: false)
        end
      end
    end
  end
end
