class Project
  include Mongoid::Document
  
  field :start_date,    type: DateTime
  field :state,         type: Symbol

  belongs_to :service
  embeds_many :answers
  validate :validate_project

  def validate_project
    results = self.service.questions.map {|q|
        answer = answer_for(q)
        answer && q.validate_answer(a.answer) }
    results.all? {|r| r}
  end

  def answer_for(name)
    name = name.name if name.is_a? Question
    self.answers.where(name: name).first
  end
end
