class UserMailer < ActionMailer::Base
  default from: "Bento <info@usebento.com>"

  def new_generated_user_mail(user, password, project) 
    @user       = user
    @password   = password
    @project    = project

    mail(to:        user.email,
         subject:   "Welcome to Bento")
  end
end
