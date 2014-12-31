class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :start_date,    type: DateTime
  field :state,         type: Symbol
  field :status,        type: Symbol  # :pending, :assigned, :awaiting_payment, :closed
  field :number,        type: Integer

  belongs_to :service
  belongs_to :user
  embeds_many :answers
  validate :is_valid?

  def validate_project
    errors = []
    results = self.service.questions.map { |question|
        answer = answer_for(question)
        if !answer
          errors.push({valid:     false, 
                       answer:    nil, 
                       question:  question,
                       message:  "This field is required"})
        else
          valid = question.validate_answer(answer)
          if (!valid[:valid])
            errors.push valid
          end
        end }
    errors
  end

  def add_answer(name, answer)
    if self.service.has_question(name)
      self.answers.push(Answer.new({name:   name,
                                    answer: answer}))
    end
  end

  def is_valid?
    validate_project.length == 0
  end

  def answer_for(name)
    name = name.name if name.is_a? Question
    self.answers.where(name: name).first || Answer.new
  end

  def get_pages
    names = ['number_of_screens', 'slide_count', 'pages']
    answers = names.map { |name|
                answer = self.answer_for(name)
                answer ? answer.answer : false }
    answers = answers.select {|a| a}
    answers.empty? ? 1 : answers[0]
  end

  def get_responsive
    answer = self.answer_for('responsiveness')
    answer ? answer.answer == 'desktop_plus_mobile' : false
  end

  def get_price
    pages          = get_pages
    price_per_page = self.service.price + (self.get_responsive ? 20 : 0)

    price_per_page * pages
  end
end
