class UserMailer < ActionMailer::Base
  default from: "info@usebento.com"

  def new_generated_user_mail(user, password) 
    @user       = user
    @password   = password

    mail(to:        user.email,
         subject:   "Your new account password for Bento")
  end
end
