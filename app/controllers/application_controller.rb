require 'gon'
require "application_responder"

class ApplicationController < ActionController::Base
  self.responder = ApplicationResponder
  respond_to :html

  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_filter :configure_permitted_parameters, if: :devise_controller?
  before_filter :reject_locked!, if: :devise_controller?
  before_filter :default_headers
  before_filter :add_gon_variables
  before_filter :ensure_signup_complete, only: [:new, :create, :update, :destroy]


  rescue_from Encoding::CompatibilityError do |exception|
    log_exception(exception)
    render "errors/encoding", layout: "errors", status: 500
  end

  rescue_from ActiveRecord::RecordNotFound do |exception|
    log_exception(exception)
    render "errors/not_found", layout: "errors", status: 404
  end

  rescue_from ActionView::Template::Error do |exception|
    log_exception(exception)
    render "errors/template_error", layout: "errors", status: 404
  end

  # From https://github.com/plataformatec/devise/wiki/How-To:-Simple-Token-Authentication-Example
  # https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
  def authenticate_user_from_token!
    user_token = if params[:authenticity_token].presence
                   params[:authenticity_token].presence
                 elsif params[:private_token].presence
                   params[:private_token].presence
                 end
    user       = user_token && User.find_by_authentication_token(user_token.to_s)

    if user
      # Notice we are passing store false, so the user is not
      # actually stored in the session and a token is needed
      # for every request. If you want the token to work as a
      # sign in token, you can simply remove store: false.
      sign_in user, store: false
    end
  end

  def log_exception(exception)
    application_trace = ActionDispatch::ExceptionWrapper.new(env, exception).application_trace
    application_trace.map! { |t| "  #{t}\n" }
    logger.error "\n#{exception.class.name} (#{exception.message}):\n#{application_trace.join}"
  end

  def cache_history
    return true unless current_user
    current_user.add_history_link(params)
  end

  def render_403
    head :forbidden
  end

  def render_401
    render file: Rails.root.join("public", "401"), layout: false, status: "401"
  end

  def render_404
    render file: Rails.root.join("public", "404"), layout: false, status: "404"
  end

  def dev_tools
  end

  def default_headers
    headers['X-Frame-Options']           = 'DENY'
    headers['X-XSS-Protection']          = '1; mode=block'
    headers['X-UA-Compatible']           = 'IE=edge'
    headers['X-Content-Type-Options']    = 'nosniff'
    # Errors if the server (nginx) already sets this
    headers['Strict-Transport-Security'] = 'max-age=31536000 [; includeSubdomains]' if Incudia.config.https
  end

  def add_gon_variables
    # gon.api_version = API::API.version
    gon.relative_url_root = Incudia.config.relative_url_root rescue nil
    if current_user
      gon.current_user_id = current_user.id
      gon.api_token       = current_user.authentication_token
    end
  end

  # Devise permitted params
  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(
        :email,
        :password,
        :password_confirmation)
    }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(
        :email,
        :password,
        :password_confirmation,
        :current_password
    )
    }
  end

  # Redirects on successful sign in
  def after_sign_in_path_for(resource)
    root_path
  end

  # Auto-sign out locked users
  def reject_locked!
    if current_user && current_user.locked?
      sign_out current_user
      user_session   = nil
      current_user   = nil
      flash[:alert]  = "Your account is locked."
      flash[:notice] = nil
      redirect_to root_url
    end
  end

  helper_method :reject_locked!

  # Only permits admin users
  def require_admin!
    authenticate_user!

    if current_user && !current_user.admin?
      redirect_to root_path
    end
  end

  helper_method :require_admin!

  def ensure_logged_in!
    unless current_user
      flash[:notice] = "You need to log in"
      redirect_to new_user_session_path
    end
  end

  helper_method :ensure_logged_in!

  def ensure_signup_complete
    # Ensure we don't go into an infinite loop
    return if action_name == 'finish_signup'

    # Redirect to the 'finish_signup' page if the user
    # email hasn't been verified yet
    if current_user && !current_user.email_verified?
      redirect_to finish_signup_path(current_user)
    end
  end

  # JSON for infinite scroll via Pager object
  def pager_json(partial, count)
    html = render_to_string(
        partial,
        layout:  false,
        formats: [:html]
    )

    render json: {
               html:  html,
               count: count
           }
  end

  def view_to_html_string(partial)
    render_to_string(
        partial,
        layout:  false,
        formats: [:html]
    )
  end

end
