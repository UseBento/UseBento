class Answer
  include Mongoid::Document

  field :name, type: String
  field :answer, type: String
  
  embedded_in :project
#  validate :validate_answer

  def validate_answer
    self.question.validate_answer(self)
  end

  def question
    self.project.service.lookup_question(self.name)
  end
end
