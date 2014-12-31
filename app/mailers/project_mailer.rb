class ProjectMailer < ActionMailer::Base
  default from: "admin@usebento.com"
  
  def new_project_mail(project) 
    @user       = project.user
    @service    = project.service
    @project    = project
    @admin      = User.get_admin
    
    mail(to:      @admin.email, 
         subject: @user.company + " started a new " + @service.name + " project")
  end
end
