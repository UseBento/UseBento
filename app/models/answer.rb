class Answer
  include Mongoid::Document

  field :name, type: String
  field :answer, type: String
  
  has_one :question
  embedded_in :project
  validate :validate_answer

  def validate_answer
    self.question.validate_answer(self)
  end
end
