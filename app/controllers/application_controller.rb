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

    user = User.new
    # user.name = params['field-full-name']
    user.email = params['field-e-mail']
    user.password = params['field-password']
    user.designer = true
    user.name = params['field-full-name']

    designer_profile = DesignerProfile.new
    # designer_profile.full_name = params['field-full-name']
    designer_profile.portfolio_url = params['field-portfolio-url']
    designer_profile.dribble_url = params['field-dribbble-url']
    designer_profile.behance_url = params['field-behance-url']
    designer_profile.skill_1 = params['skill']
    designer_profile.skill_2 = params['skill2']
    designer_profile.skill_3 = params['skill3']
    user.designer_profile = designer_profile
    # 

    @message_sent = user.save
    @errors = user.errors

    # binding.pry
    if @message_sent
      sign_in(:user, user)
      redirect_to '/profile'
      return
    end
    respond_to do |format|
      format.html {
          # @message_sent = true
          render 'apply' }
      format.json { render json: {success: true} }
    end
  end

  def get_attachments(parent)
    files = params.select {|a,b| a.to_s.slice(0, 12) == "file-upload-"}
    logger.debug(files);
    files.map do |key, file_list|
      file_list = Array(files[key])
      file_list.map do |file|
        # attachment = Attachment.new({uploaded_date:   DateTime.now,
        #                              name:            file.original_filename})

        attachment = Attachment.new({uploaded_date:   DateTime.now,
                                     name:            file.original_filename,
                                     is_amazon_s3:    true})
        attachment.attachment = file
        parent.attachments.push(attachment)
        logger.debug('made new file');
      end
    end
  end
end
