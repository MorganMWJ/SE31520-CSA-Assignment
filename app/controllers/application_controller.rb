# Superclass that manages authentication and authorisation using
# basic authentication for REST client requests and form-based authentication
# for the human web (browser requests)
# @author Chris Loftus and https://github.com/technoweenie/restful-authentication
class ApplicationController < ActionController::Base
  helper_method :is_admin?, :logged_in?, :current_user
  protect_from_forgery with: :exception

  before_action :login_required

  protected

  def login_required
    logged_in? || access_denied
  end

  # To support RESTful authentication we need to treat web
  # browser access differently to web service B2B style interaction:
  # o For HTML C2B based requests we redirect users to a login
  #   screen as part of form-based authentication. Note that we store the
  #   original request URI in the user's session so that we
  #   can go there after they have submitted
  #   their credentials. We cannot redirect non-human
  #   users and so this doesn't work for B2B web service
  #   requests.
  # o For B2B web service request requiring XML or JSON we rely
  #   on HTTP Basic Authentication.
  #   If the Accept header or extension specifies JSON or XML
  #   then a 401 status response is sent to the caller with
  #   WWW-Authenticate header set, i.e. requesting the credentials
  def access_denied
    respond_to do |format|
      format.html do
        session[:original_uri] = request.fullpath
        flash[:notice] = 'Please log in'
        redirect_to new_session_url
      end
      format.any(:json, :xml) do
        request_http_basic_authentication 'Web Password'
      end
    end
  end

  def login_from_session
    self.current_user =
        UserDetail.find_by_id(session[:user_id]) if session[:user_id]
  end

  def login_from_basic_auth
    authenticate_with_http_basic do |login, password|
      UserDetail.authenticate(login, password)
    end
  end

  def logged_in?
    current_user ? true : false
  end

  # Accesses the current user from either the session or via a
  # db lookup as part of basic authentication.
  def current_user
    login_from_session || login_from_basic_auth
  end

  # Store the given user id in the session.
  def current_user=(new_user)
    session[:user_id] = new_user ? new_user.id : nil
  end

  # Some very lightweight authorisation checking
  def is_admin?
    current_user ? current_user.login == 'admin' : false
  end

  def admin_required
    is_admin? || admin_denied
  end

  def admin_denied
    respond_to do |format|
      format.html do
        flash[:error] = 'You must be admin to do that'
        redirect_to root_url
      end
    end
  end
end

