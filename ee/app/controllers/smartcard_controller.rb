# frozen_string_literal: true

class SmartcardController < ApplicationController
  skip_before_action :authenticate_user!
  skip_before_action :verify_authenticity_token

  before_action :check_feature_availability
  before_action :check_certificate_headers

  def auth
    certificate = Gitlab::Auth::Smartcard::Certificate.new(CGI.unescape(certificate_header))

    user = certificate.find_or_create_user
    unless user
      flash[:alert] = _('Failed to signing using smartcard authentication')
      redirect_to new_user_session_path(port: Gitlab.config.gitlab.port)

      return
    end

    log_audit_event(user, with: 'smartcard')
    sign_in_and_redirect(user)
  end

  protected

  def check_feature_availability
    render_404 unless ::Gitlab::Auth::Smartcard.enabled?
  end

  def check_certificate_headers
    # Failing on requests coming from the port not requiring client side certificate
    unless certificate_header.present?
      access_denied!(_('Smartcard authentication failed: client certificate header is missing.'), 401)
    end
  end

  def log_audit_event(user, options = {})
    AuditEventService.new(user, user, options).for_authentication.security_event
  end

  def certificate_header
    request.headers['HTTP_X_SSL_CLIENT_CERTIFICATE']
  end

  def after_sign_in_path_for(resource)
    stored_location_for(:redirect) || stored_location_for(resource) || root_url(port: Gitlab.config.gitlab.port)
  end
end
