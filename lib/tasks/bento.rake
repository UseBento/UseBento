namespace :bento do
  desc "TODO"
  task create_admin_user: :environment do
        User.create({email:     'admin@usebento.com',
                     name:      'admin',
                     password:  'Ben70!9n3',
                     admin:      true,
                     company:   'Bento'})
  end

end
