# frozen_string_literal: true

class Ldap::OmniauthCallbacksController < OmniauthCallbacksController
  def self.define_providers!
    return unless Gitlab::Auth::Ldap::Config.sign_in_enabled?

    Gitlab::Auth::Ldap::Config.available_servers.each do |server|
      alias_method server['provider_name'], :ldap
    end
  end

  # We only find ourselves here
  # if the authentication to LDAP was successful.
  def ldap
    return unless Gitlab::Auth::Ldap::Config.sign_in_enabled?

    sign_in_user_flow(Gitlab::Auth::Ldap::User)
  end

  define_providers!

  def set_remember_me(user)
    user.remember_me = params[:remember_me] if user.persisted?
  end

  def fail_login(user)
    # This is defined in EE::OmniauthCallbacksController. We need to add it since
    # we're overriding #fail_login from OmniauthCallbacksController.
    log_failed_login(user.username, oauth['provider'])
    flash[:alert] = _('Access denied for your LDAP account.')

    redirect_to new_user_session_path
  end
end

Ldap::OmniauthCallbacksController.prepend_if_ee('EE::Ldap::OmniauthCallbacksController')
