class BentoMailer < ActionMailer::Base
  default from: "Bento <info@usebento.com>"
  
  def contact_us(name, email, subject, message)
    @full_name     = name
    @email         = email
    @subject       = subject
    @message       = message
    @admin         = User.get_admin
    
    mail(to:       @admin.email,
         from:     name + " <" + @email + ">",
         subject:  @subject)
  end

  def contact_agency(name, email, agency, message)
    @full_name     = name
    @email         = email
    @agency        = agency
    @message       = message
    @admin         = User.get_admin
    
    mail(to:       @admin.email,
         from:     name + " <" + @email + ">",
         subject:  "Agency: " + @agency + " sent a message")
  end
  
  def apply(name, email, portfolio, dribbble, behance, skills) 
    @full_name     = name
    @email         = email
    @portfolio     = portfolio
    @dribbble      = dribbble
    @behance       = behance
    @skills        = skills
    @admin         = User.get_admin

    mail(to:        @admin.email,
         from:      name + " <" + @email + ">",
         subject:   @full_name + " applied to Bento")
  end

  def send_to_applier(name, email)
    @name     = name
    @email    = email
    @admin    = User.get_admin
    
    mail(to:        @email,
         subject:   "Bento Application Received")
  end
end
