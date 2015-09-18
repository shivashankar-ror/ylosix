class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  before_action :extract_commerce_from_url, :set_locale

  rescue_from Exception, with: :render_error

  def change_locale
    locale = I18n.default_locale.to_s
    param_locales = permit_locale

    unless param_locales[:locale].blank?
      locale_param = param_locales[:locale].parameterize.underscore.to_sym

      if I18n.available_locales.include?(locale_param)
        locale = param_locales[:locale]
      end
    end

    session[:locale] = locale
    session[:return_to] ||= request.referer || request.url || root_url

    return_url = session.delete(:return_to)
    redirect_to return_url
  end

  # Overwrite unverified request handler to force a refresh / redirect.
  def handle_unverified_request
    # super # call the default behaviour, including Devise override
    flash[:alert] = 'Error with CSRF'
    throw :warden, redirect: request.referer || request.url
  end

  # After sign in set user locale.
  def after_sign_in_path_for(resource)
    if !resource.nil? && Language.locale_valid?(resource.locale)
      session[:locale] = resource.locale
    end

    # login admin and login customer.
    if !session[:shopping_cart].blank? && !current_customer.nil?
      # TODO if exist customer shopping cart append the products.
      ShoppingCart.retrieve(current_customer, session[:shopping_cart])
      session.delete :shopping_cart
    end

    resource.intern_path
  end

  private

  def set_locale
    if session[:locale].nil?
      language = @commerce.language
      language ||= Language.find_by(default: true)

      if language.nil?
        session[:locale] = extract_locale_from_accept_language_header
      else
        session[:locale] = language.locale
      end
    end

    I18n.locale = session[:locale]
  end

  def extract_locale_from_accept_language_header
    locale = I18n.default_locale
    if !request.nil? && !request.env['HTTP_ACCEPT_LANGUAGE'].nil?
      browser = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
      browser = browser.underscore
      locale = browser if Language.locale_valid?(browser)
    end
    locale
  end

  def extract_commerce_from_url
    @commerce = Commerce.retrieve(retrieve_http_server_name)
    @render_template = @commerce.template

    unless current_admin_user.nil?
      user_template = Template.active_template(current_admin_user)
      unless user_template.nil?
        @render_template = user_template
        if current_admin_user.debug_template.nil?
          @commerce.template_from = 'default_template'
        else
          @commerce.template_from = 'admin_user'
        end
      end
    end

    @variables ||= {}
    @variables['commerce'] = @commerce.to_liquid
  end

  def retrieve_http_server_name
    http = nil
    if !request.nil? && !request.env['SERVER_NAME'].nil?
      http = request.env['SERVER_NAME']
      http = http[4..-1] if http.starts_with?('www.')
    end

    http
  end

  def permit_locale
    params.permit(:locale)
  end

  def render_error(e)
    if [ActiveRecord::RecordNotFound].include?(e.class)
      render file: 'public/404.html', formats: :html, status: 404, layout: false && return
    end
  end
end
