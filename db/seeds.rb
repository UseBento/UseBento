# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

seeds = YAML.load_file('db/seeds.yml')
seeds["Services"].map do |service_def|
    service = Service.where(name: service_def['name']).first
    if (service)
      service.title             = service_def['title']
      service.description       = service_def['description']
      service.rounds            = service_def['rounds']
      service.price             = service_def['price']
      service.plus_dev_price    = service_def['plus_dev_price']
      service.responsive_price  = service_def['responsive_price']
      service.unit              = service_def['unit']
      service.completion_time   = Range.new(service_def['completion_time'][0],
                                            service_def['completion_time'][1])
      service.save
    else
      service = Service.create(
                {name:            service_def['name'],
                 title:           service_def['title'],
                 description:     service_def['description'],
                 rounds:          service_def['rounds'],
                 unit:            service_def['unit'],
                 price:           service_def['price'],
                 plus_dev_price:  service_def['plus_dev_price'],
                 responsive_price: service_def['responsive_price'],
                 completion_time: Range.new(service_def['completion_time'][0],
                                            service_def['completion_time'][1])})
    end

    field_names = []
    service_def['fields'].map { |field_def|
        field_names.push field_def['name']
        question = service.questions.where(name: field_def['name']).first
        if question
          question.label    = field_def['label']
          question.type     = field_def['type']
          question.values   = field_def['values']
          question.required = field_def['required']
          question.save
        else
          service.questions.create({name:        field_def['name'],
                                    label:       field_def['label'],
                                    type:        field_def['type'],
                                    values:     (field_def['values'] || []),
                                    required:   (field_def['required'] || false)})
        end }
    service.questions.map do |question|
      if !field_names.member?(question.name)
        question.delete
      end 
    end
end
  
