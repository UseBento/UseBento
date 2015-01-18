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
  def contact_agency(name, email, agency, message)
    @full_name     = name
    @email         = email
    @agency        = agency
    @message       = message
    @admin         = User.get_admin
    
    mail(to:       @admin.email,
         from:     @email,
         subject:  "Agency: " + @agency + " sent a message")
  end
end
