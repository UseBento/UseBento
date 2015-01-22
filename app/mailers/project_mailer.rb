class ProjectMailer < ActionMailer::Base
  default from: "info@usebento.com"
  
  def new_project_mail(project) 
    @user       = project.user
    @service    = project.service
    @project    = project
    @admin      = User.get_admin

    mail(to:      @admin.email, 
         subject: @user.company + " started a new " + @service.name + " project")
  end

  def new_admin_message_mail(message) 
    @message    = message
    @project    = message.project
    @owner      = @project.user
    @admin      = @message.user

    mail(to:      @owner.email,
         subject: "New message from " + @admin.full_name)
  end
end
