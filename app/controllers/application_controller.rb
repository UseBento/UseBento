class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def redirect_to_login
    redirect_to "/users/sign_in"
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

  def get_attachments(parent)
    files = params.select {|a,b| a.to_s.slice(0, 11) == "file-upload"}
    files.map do |key, file|
           attachment = 
             parent.attachments.create({uploaded_date:   DateTime.now,
                                        name:            file.original_filename})
           attachment.attachment = file
           attachment.save
         end
  end
end
