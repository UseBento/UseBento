namespace :bento do
  desc "TODO"
  task create_admin_user: :environment do
        User.create({email:     'admin@usebento.com',
                     name:      'admin',
                     password:  'Ben70!9n3',
                     admin:      true,
                     company:   'Bento'})
  end
  
  task check_mailers: :environment do
    Message.get_email_replies
  end
  
  task update_companies: :environment do
        Project.all.map do |p|
                     p.update_company
                   end
  end

  task service_update: :environment do
    Service.all.each do |service|
      service.questions.create({name:        'pages',
                                label:       'Number of estimated pages',
                                type:        ':text',
                                values:      nil,
                                required:   false})

      service.questions.create({name:        'design_andor_development',
                                label:       'Design or Design + Development',
                                type:        ':text',
                                values:      nil,
                                required:   false})

      if service.name == "business_card"
        service.title = "Custom"
        service.save
      elsif service.name == "stationary_design"
        service.title = "White Paper"
        service.save
      elsif service.name == "email_design_and_development"
        service.price = 350
        service.plus_dev_price = 650
        service.save
      elsif service.name == "landing_page_design_and_development"
        service.price = 650
        service.plus_dev_price = 1500
        service.save
      end
    end
  end
end
