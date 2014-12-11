class Project
  include Mongoid::Document
  
  field :start_date,    type: DateTime
  field :state,         type: Symbol

  belongs_to :service
  embeds_many :answers
  validate :is_valid?

  def validate_project
    errors = []
    results = self.service.questions.map { |question|
        answer = answer_for(question)
        if !answer
          errors.push {valid:     false, 
                       answer:    nil, 
                       question:  question,
                       message:  "This field is required"}
        else
          valid = question.validate_answer(answer)
          if (!valid[:valid])
            errors.push valid
          end
        end }
    errors
  end

  def is_valid?
    validate_project.length == 0
  end

  def answer_for(name)
    name = name.name if name.is_a? Question
    self.answers.where(name: name).first
  end
end
