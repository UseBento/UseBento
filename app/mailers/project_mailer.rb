class ProjectMailer < ActionMailer::Base
  default from: "Bento <email@usebento.com>"

  def new_project_mail(project)
    @user       = project.user
    @service    = project.service
    @project    = project

    # @admin      = User.get_admin
    # if !@admin.nil?
    #   mail(to:      @admin.email,
    #      subject: @user.company + " started a new " + @service.name + " project")
    # end

    # @custom_admin      = User.get_custom_admin

    # if !@custom_admin.nil?
    #   mail(to:      @custom_admin.email,
    #      subject: @user.company + " started a new " + @service.name + " project")
    # end

    @amdin_list = User.get_admin_list
    if @amdin_list.blank?
      @amdin_list.each do |admin_user|
        mail(to:      admin_user.email,
          subject: @user.company + " started a new " + @service.name + " project")
      end
    end
    
  end

  def new_project_request_mail(name, email, company, company_size, description)
    @name          = name
    @email         = email
    @company       = company
    @company_size  = company_size
    @description   = description
    @admin         = User.get_admin

    if !@admin.nil?
      mail(to:      @admin.email,
         subject: @company + " wants to start a new project")
    end
    
  end

  def new_admin_message_mail(message)
    @message    = message
    @project    = message.project
    @owner      = @project.user
    @admin      = @message.user

    if !@admin.nil?
      mail(to:      @owner.email,
         subject: "New message from " + @admin.full_name)
    end
    
  end

  def new_user_message_mail(to_first_name, from_full_name, message_body, link_path, email, code)
    @first_name  = to_first_name
    @full_name   = from_full_name
    @body        = message_body
    @link_path   = link_path
    @code        = code

    mail(to:      email,
      subject: "New message from " + @full_name)
    
  end

  # def project_status_update_mail(project, user)

  #   @full_name   = user.full_name
  #   project.people.each do |person|
  #     mail(to: person.email, 
  #       subject: "Project status updated")
  #   end

  #   project.designers.each do |designer|
  #     mail(to: designer.email, 
  #       subject: "Project status updated")
  #   end
  # end

  def project_status_update_mail(project, to_first_name, from_full_name, to_email)
    @project = project
    @from_full_name = from_full_name
    @to_first_name = to_first_name
    if @project.status_index >= 0
      @message = "#{@project.name} has been updated to the milestone #{Project::STATUS_LIST[@project.status_index]}"
    else
      @message = "#{@project.name} has been updated to the milestone"
    end
    mail(to: to_email, 
      subject: "Project status updated")
  end

end
