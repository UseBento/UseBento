namespace :bento do
  desc "TODO"
  task create_admin_user: :environment do
        User.create({email:     'admin@usebento.com',
                     name:      'admin',
                     password:  'Ben70!9n3',
                     admin:      true,
                     company:   'Bento'})
  end

  task update_companies: :environment do
        Project.all.map do |p|
                     p.update_company
                   end
      end
end
