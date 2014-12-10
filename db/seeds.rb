# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

seeds = YAML.load_file('db/seeds.yml')
seeds["Services"].map { |service_def|
    service = Service.create(
                {name: service_def['name'],
                 title: service_def['title'],
                 description: service_def['description'],
                 rounds: service_def['rounds'],
                 price: service_def['price'],
                 completion_time: Range.new(service_def['completion_time'][0],
                                            service_def['completion_time'][1])})
    service_def['fields'].map { |field_def| 
        service.questions.create({name: field_def['name'],
                                  label: field_def['label'],
                                  type: field_def['type'],
                                  values: (field_def['values'] || []),
                                  required: (field_def['required'] || false)}) }}
