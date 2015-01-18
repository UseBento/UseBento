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
end
