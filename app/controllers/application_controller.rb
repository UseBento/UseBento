class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def redirect_to_login
    redirect_to "/#login"
  end

  def contact
    @message_sent = false
  end

  def send_contact
    BentoMailer.contact_us(params['field-name'], 
                           params['field-e-mail'],
                           params['field-subject'],
                           params['field-message']).deliver

    respond_to do |format|
      format.html { 
          @message_sent = true
          render 'contact' }
      format.json { render json: {success: true} }
    end
  end

  def contact_agency
    BentoMailer.contact_agency(params['field-name'], 
                               params['field-e-mail'],
                               params['field-agency'],
                               params['field-message']).deliver

    respond_to do |format|
      format.html { 
          @message_sent = true
          render 'agencies' }
      format.json { render json: {success: true} }
    end
  end

  def send_apply
    skills = [params['skill'], 
              params['skill2'], 
              params['skill3']].select do |skill|
                                 skill
                               end

    BentoMailer.apply(params['field-full-name'],
                      params['field-e-mail'],
                      params['field-portfolio-url'],
                      params['field-dribbble-url'],
                      params['field-behance-url'],
                      skills).deliver

    BentoMailer.send_to_applier(params['field-full-name'],
                                params['field-e-mail']).deliver

    respond_to do |format|
      format.html { 
          @message_sent = true
          render 'apply' }
      format.json { render json: {success: true} }
    end
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

end
