class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :start_date,    type: DateTime
  field :state,         type: Symbol
  field :status,        type: Symbol  # :pending, :assigned, :awaiting_payment, :closed
  field :last_status,   type: Symbol  # set to keep track of last status before archiving
  field :number,        type: Integer
  field :deadline,      type: Date

  belongs_to :service
  belongs_to :user
  embeds_many :answers
  embeds_many :messages
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
    if self.service.name == "social_media_design"
      fields = ["twitter_header_and_profile", 
                "youtube_header_and_profile", 
                "linkedin_header_and_profile", 
                "facebook_header_and_profile"]
      fields = fields.map {|f| self.answer_for(f).answer }
      fields = fields.select {|f| f}
      fields.length
    else
      names = ['number_of_screens', 'slide_count', 'pages']
      answers = names.map { |name|
                  answer = self.answer_for(name)
                  answer ? answer.answer : false }
      answers = answers.select {|a| a}
      answers.empty? ? 1 : answers[0].to_i
    end
  end

  def get_responsive
    answer = self.answer_for('responsiveness')
    answer ? answer.answer == 'desktop_plus_mobile' : false
  end

  def get_plus_dev
    answer = self.answer_for('service')
    answer ? answer.answer == 'design_and_development' : false
  end

  def get_price
    pages          = get_pages
    price_per_page = self.service.price
    if self.get_plus_dev
      if self.service.plus_dev_price
        price_per_page = self.service.plus_dev_price
      end
    end

    if self.get_responsive
      if self.service.responsive_price
        price_per_page = self.service.responsive_price
      else
        price_per_page += 20
      end
    end

    price_per_page * pages
  end

  def archived?
    self.status == :closed
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

  def label_class
    case self.status
    when :pending
      "btn_small blue"
    when :assigned
      "btn_small green"
    when :awaiting_payment
      "btn_small blue"
    when :closed
      "btn_small gray"
    end
  end

  def initialize_project
    message_body = ("Hi there! My name is Noah and I'm your project manager. " +
                    "Its my job to make sure your project gets done quickly and " +
                    "professionally. If you have any questions just write them in " +
                    "the message field below and I'll get back to you ASAP. \n\n" +
                    
                    "If you're ready to get your project started now, just pay your " +
                    "first invoice by clicking the \"Pay Invoice Now\" button on the " +
                    "right. Looking forward to working with you and please let me " +
                    "know if you have any questions!")

    admin_user   = User.where({admin: true, name: "Noah"}).first
    admin_user   = User.where({admin: true}).first unless admin_user
    message      = self.messages.create({body:        message_body,
                                         posted_date: DateTime.now})
    message.user = admin_user
    message.save
  end
end
