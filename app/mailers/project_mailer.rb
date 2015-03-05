class ProjectMailer < ActionMailer::Base
  default from: "Bento <info@usebento.com>"

  def new_project_mail(project)
    @user       = project.user
    @service    = project.service
    @project    = project
    @admin      = User.get_admin

    mail(to:      @admin.email,
         subject: @user.company + " started a new " + @service.name + " project")
  end

  def new_project_request_mail(name, email, company, company_size, description)
    @name          = name
    @email         = email
    @company       = company
    @company_size  = company_size
    @description   = description
    @admin         = User.get_admin

    mail(to:      @admin.email,
         subject: @company + " wants to start a new project")
  end

  def new_admin_message_mail(message)
    @message    = message
    @project    = message.project
    @owner      = @project.user
    @admin      = @message.user

    mail(to:      @owner.email,
         subject: "New message from " + @admin.full_name)
  end

  def new_user_message_mail(message, to, from)
    @message    = message
    @attachments = message.attachments
    @project    = message.parent_project
    @to         = to
    @from       = from

    mail(to:      @to.email,
         subject: "New message from " + @from.full_name)
  end
end
