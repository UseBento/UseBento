class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :start_date,    type: DateTime
  field :state,         type: Symbol
  field :status,        type: Symbol  # :pending, :assigned, :awaiting_payment, :closed
  field :number,        type: Integer
  field :deadline,      type: Date

  belongs_to :service
  belongs_to :user
  embeds_many :answers
  validate :is_valid?
  has_many :payments

  def has_access?(user) 
    (user.id == self.user.id) || user.admin
  end

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

  def update_answer(name, new_answer)
    answer = self.answer_for(name)
    if answer
      answer.answer = new_answer
    end
  end

  def is_valid?
    validate_project.length == 0
  end

  def answer_for(name)
    name = name.name if name.is_a? Question
    self.answers.where(name: name).first || Answer.new
  end

  def print_pages
    pages = get_pages
    unit = self.service.unit

    if (pages > 1)
      unit = unit.pluralize
    end
    pages.to_s + ' ' + unit
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

  def format_start_date
    (self.start_date || DateTime.now).strftime "%b %d, %Y"
  end

  def number_format
    self.number.to_s.rjust(4,'0')
  end

  def people
    [self.user]
  end

  def get_features
    features = []
    featured_answers = 
      {"ftp_upload"                => "FTP Upload",
       "google_analytics_setup"    => "Google Analytics Setup",
       "presentation_type"         => {"Powerpoint"             => "Powerpoint <>",
                                       "Keynote"                => "Keynote <>"},
       "type"                      => {"apple_ios"              => "iOS <>",
                                       "android"                => "Android <>"},
       "responsiveness"            => {"desktop"                => false,
                                       "desktop_plus_mobile"    => "Responsive <>"},
       "service"                   => {"design_only"            => "Design Only",
                                       "design_and_development" => "Design and Development"},
       "facebook_header_and_profile" => "Facebook Header & Profile",
       "twitter_header_and_profile"  => "Twitter Header & Profile",
       "youtube_header_and_profile"  => "Youtube Header & Profile",
       "linkedin_header_and_profile" => "LinkedIn Header & Profile"}

    featured_answers.map do |name, label|
                      answer = self.answer_for(name).answer
                      if answer
                        label = label[answer]                      if !label.is_a? String
                        features.push(label.sub("<>", self.service.title)) if label
                      end
                    end
    features
  end

  def total_payments
    2
  end

  def current_payment
    self.payments.count + 1
  end

  def next_payment_price
    self.get_price / 2
  end
end
