# Superclass that manages authentication and authorisation using
# basic authentication for REST client requests and form-based authentication
# for the human web (browser requests)
# @author Chris Loftus and https://github.com/technoweenie/restful-authentication
class ApplicationController < ActionController::Base
  helper_method :is_admin?, :logged_in?, :current_user

  # The current trend is to use HTTPS for all web app
  # communication. Note that we have switch on SSL and
  # specified its port in config/environments/development.rb
  #force_ssl

  protect_from_forgery with: :exception

  before_action :set_locale
  before_action :login_required
  after_action :store_location, only: [:index, :new, :show, :edit, :search]

  # Get the last 20 notifications for display on all pages when logged in
  before_action :get_notifications

  def login_requiredl
    logged_in? || access_denied
  end

  # To support RESTful authentication we need to treat web
  # browser access differently
  # to web service B2B style interaction:
  # o For HTML C2B based requests we redirect users to a login
  #   screen as part of
  #   form-based authentication. Note that we store the original request
  #   URI in the user's session so that we can go there after
  #   they have submitted their credentials. We cannot redirect non-human
  #   users and so this doesn't work for B2B web service requests.
  # o For B2B web service request requiring XML or JSON we rely
  #   on HTTP Basic Authentication.
  #   If the Accept header specifies JSON or XML then
  #   a 401 status response is sent to the caller with WWW-
  #   Authenticate header set, i.e. requesting the credentials
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

  # Store the given user id in the session. We cheat a bit and
  # do this even
  # for basic authentication. If the session cookie is handled
  # by the caller
  # then let's take advantage of it. Perhaps breaks spirit of
  # REST a little but improves performance where we can.
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

  # Store the URI of the current request in the session.
  #
  # We can return to this location by calling #redirect_back_or_default.
  def store_location
    session[:return_to] = request.fullpath
  end

  # Redirect to the URI stored by the most recent store_location call or
  # to the passed default.  Set an appropriately modified
  #   after_action :store_location, :only => [:index, :new, :show, :edit]
  # for any controller you want to be bounce-backable.
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def set_locale
    session[:locale] = params[:locale] if params[:locale]
    I18n.locale = session[:locale] || I18n.default_locale

    locale_path = "#{LOCALES_DIRECTORY}#{I18n.locale}.yml"

    unless I18n.load_path.include? locale_path
      I18n.load_path << locale_path
      I18n.backend.send(:init_translations)
    end
  rescue Exception => err
    logger.error err
    flash.now[:notice] = "#{I18n.locale} translation not available"

    I18n.load_path -= [locale_path]
    I18n.locale = session[:locale] = I18n.default_locale
  end

  # Code taken from Kieran Dunbar's 2016-17 assignment solution
  def get_notifications
    @notifications = Broadcast.joins(:feeds).where(feeds: {name: "notification"}).order(created_at: :desc).limit(20)
  end

end
