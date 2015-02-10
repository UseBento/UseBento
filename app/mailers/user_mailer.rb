class UserMailer < ActionMailer::Base
  default from: "Bento <info@usebento.com>"

  def new_generated_user_mail(user, password, project) 
    @user       = user
    @password   = password
    @project    = project

    mail(to:        user.email,
         subject:   "Welcome to Bento")
  end

  def invited_to_project_mail(invitation, project, inviter)
    @invitation  = invitation
    @project     = project
    @inviter     = inviter

    mail(to:       @invitation.email,
         subject:  @inviter.full_name + " invited you to join a project on Bento")
  end
end
