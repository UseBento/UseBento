class BentoMailer < ActionMailer::Base
  default from: "info@usebento.com"
  
  def contact_us(name, email, subject, message)
    @full_name     = name
    @email         = email
    @subject       = subject
    @message       = message
    @admin         = User.get_admin
    
    mail(to:       @admin.email,
         from:     @email,
         subject:  @subject)
  end
end
