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

  task service_question_pages_remove: :environment do
    Service.all.each do |service|
      service.remove_question('pages')
      service.remove_question('design_andor_development')
    end
  end

  task service_update: :environment do
    Service.all.each do |service|
      if service.has_question('pages').nil?

        label_str = "Number of pages"
        if service.name == "email_design_and_development"
          label_str = "Number of emails"
        elsif service.name == "presentation_design"
          label_str = "Number of slides"
        elsif service.name == "social_media_design"
          label_str = "Number of ads"
        elsif service.name == "banner_ads"
          label_str = "Number of ads"
        end
        service.questions.create({name:        'pages',
                                label:       label_str,
                                type:        ':text',
                                values:      nil,
                                required:   false})  

        puts 'Service pages save'
      end
      if service.has_question('design_andor_development').nil?
        service.questions.create({name:        'design_andor_development',
                                label:       'Design or Design + Development',
                                type:        ':text',
                                values:      nil,
                                required:   false})
        puts 'Service design and development save'
      end



      if service.name == "business_card"
        service.title = "Custom"
        if service.save
          puts 'Custom save'
        end
      elsif service.name == "stationary_design"
        service.title = "White Paper"
        if service.save
          puts 'White Paper save'
        end
      elsif service.name == "email_design_and_development"
        service.price = 350
        service.plus_dev_price = 650
        if service.save
          puts 'Email save'
        end
      elsif service.name == "landing_page_design_and_development"
        service.price = 650
        service.plus_dev_price = 1500
        if service.save
          puts 'Landing save'
        end
      end
    end
  end

  task service_white_paper_price_update: :environment do
    Service.all.each do |service|
      if service.name == "stationary_design"
        service.price = 100
        if service.save
          puts 'White paper price updated.'
        end
      end
    end
  end

end
