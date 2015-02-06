class RegistrationsController < Devise::RegistrationsController
  def new
    super
  end

  def create
    super
  end

  def update
    super
  end

  before_action :configure_devise_permitted_parameters, if: :devise_controller?

  protected
  
  def configure_devise_permitted_parameters
    registration_params = [:name, :email, :password, :company]

    if params[:action] == 'update'
      devise_parameter_sanitizer.for(:account_update) { 
        |u| u.permit(registration_params << :current_password)
      }
    elsif params[:action] == 'create'
      devise_parameter_sanitizer.for(:sign_up) { 
        |u| u.permit(registration_params) 
      }
    end
  end

  private

  def after_sign_up_path_for(resource)
    session[:user_return_to] || root_path
  end

  def after_inactive_sign_up_path_for(resource)
    session[:user_return_to] || root_path
  end
end 
