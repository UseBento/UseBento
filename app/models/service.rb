class Service
  include Mongoid::Document
  field :name,            type: String
  field :title,           type: String
  field :description,     type: String
  field :rounds,          type: Integer
  field :completion_time, type: Range
  field :price,           type: Integer
  field :plus_dev_price,  type: Integer
  field :unit,            type: String
  field :responsive_price, type: Integer

  has_many :project
  embeds_many :questions

  def lookup_question(name) 
    self.questions.where(name: name).first
  end

  def create_project(answers) 
    project = Project.new
    project.service = self
    project.start_date = DateTime.now
    
    answers.each { |name, answer|
        project.answers.push Answer.new(name: name, answer: answer) }

    if !project.validate_project
      raise Exceptions::ValidationError.new(project: project)
    end
    project
  end

  def partial_name
    self.name + '_form'
  end

  def has_question(name) 
    self.questions.where(name: name).first
  end
end
