class Project
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :start_date,    type: DateTime
  field :state,         type: Symbol
  field :status,        type: Symbol  # :pending, :assigned, :awaiting_payment,
                                      # :in_progress, :closed
  field :status_index,   type: Integer, default: 0

  field :last_status,   type: Symbol  # set to keep track of last status before archiving
  field :number,        type: Integer
  field :deadline,      type: Date
  field :company,       type: String
  field :total_price,   type: Integer
  field :shown_popup,   type: Boolean

  belongs_to :service
  belongs_to :user
  embeds_many :answers
  embeds_many :messages
  embeds_many :invited_users
  embeds_many :attachments
  validate :is_valid?
  has_many :payments
  has_many :awaiting_payments
  
  STATUS_LIST = ['Project Started', 'Creative Brief', 'First Round Designs', 'Second Round Designs', 'Development', 'Files Delivered']
  
  def as_json(i=0)
    {start_date:       start_date,
     state:            state,
     status:           status,
     status_index:           status_index,
     number:           number,
     company:          company,
     deadline:         deadline,
     price:            self.get_price,
     payments:         self.payments,
     unpaid_payments:  self.awaiting_payments}
  end

  def was_invited?(user)
    self.invited_users.where(user_id: user.id).first
  end

  def people
    people = self.invited_users

    if (people.empty?)
      invited_user         = self.invited_users.create({accepted: true})
      invited_user.user    = self.user
      invited_user.save
      people = self.invited_users
    end

    if (people.select {|person| person.user && person.user.admin}).empty?
      invited_user         = self.invited_users.create({accepted: true})
      invited_user.user    = User.get_admin
      invited_user.save
      people = self.invited_users
    end

    people
  end

  def owner
    self.user
  end

  def get_awaiting_payments(all=false)
    paid_payments     = self.payments.to_a
    unpaid_payments   = self.awaiting_payments.to_a
    amount            = self.get_price
    logged_amount     = 0

    paid_payments.each do |payment|
                   logged_amount += payment.amount
                 end
    unpaid_payments.each do |payment|
                     logged_amount += payment.amount
                   end
    
    if (logged_amount < amount)
      payments_needed = 2 - (paid_payments.length + unpaid_payments.length)
      if (payments_needed > 0)
        (1..payments_needed).each {|i|
            unpaid_payments.push(
                self.awaiting_payments.create({amount: ((amount - logged_amount) / 
                                                        payments_needed),
                                               paid:   false})) }
      else
        if unpaid_payments.length > 0
          fix_awaiting_payment_amounts(paid_payments, unpaid_payments, amount)
        end
      end
    elsif amount < logged_amount
      if unpaid_payments.length > 0
        fix_awaiting_payment_amounts(paid_payments, unpaid_payments, amount)
      end
    end      

    paid_payments.concat unpaid_payments
  end

  def fix_awaiting_payment_amounts(paid_payments, unpaid_payments, amount)
    paid_amount   = (paid_payments.to_a.map {|p| p.amount }).reduce(&:+) || 0
    new_amount    = (amount - paid_amount) / unpaid_payments.length

    unpaid_payments.each do |payment|
                     payment.amount = new_amount
                     payment.save
                   end

    if (new_amount * 2) < (amount - paid_amount)
      unpaid_payments.last.amount += 1
      unpaid_payments.last.save
    end
  end
    
  def has_access?(user) 
    (user && 
     (user.id == self.user.id || 
      user.admin || 
      self.invited_users.where(accepted: true).where(user_id: user.id).first))
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
    if answer && answer.project == self || service.has_question(name)
      answer.answer   = new_answer
      answer.save
    end
  end

  def self.normalize_company(company)
    company.downcase.split(" ").join(" ")
  end

  def update_company
    self.company = Project.normalize_company(self.business_name)
    self.save
  end

  def is_valid?
    validate_project.length == 0
  end

  def answer_for(name)
    name = name.name if name.is_a? Question
    self.answers.where(name: name).first || answers.new({name: name})
  end

  def business_name
    answer_for(:business_name).answer
  end

  def name
    answer_for(:project_name).answer || ""
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
    return self.total_price if (self.total_price)
    
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
    self.awaiting_payments.first
    self.payments.count + 1
  end

  def next_payment_price
    next_payment = self.awaiting_payments.first
    next_payment ? next_payment.amount : false
  end

  def label_class
    case self.status
    when :pending
      "btn_small blue"
    when :assigned
      "btn_small green"
    when :in_progress
      "btn_small green"
    when :awaiting_payment
      "btn_small blue"
    when :closed
      "btn_small gray"
    end
  end

  def filled_out_creative_brief?
    brief_answers = ['desired_visitor_action', 'competitors', 'tagline', 
     'color_preferences', 'font_preferences', 'inspiration', 
     'definite_nos', 'other_info'].select do |name|
                                    answer_for(name).answer
                                  end
    !brief_answers.empty?
  end

  def bot_message(message_body)
    admin_user   = User.get_admin
    message      = self.messages.create({body:        message_body,
                                         posted_date: DateTime.now})
    message.user = admin_user
    message.save
  end    

  def filled_out_message
    bot_message """Thanks for filling out the creative brief. We are now finding the right designer to work on this project and will get back to you shortly. Also, can you please pay the deposit for this project when you get a chance? This is fully refundable until we actually start your project."""
  end

  def initialize_project
    bot_message """Hi there! My name is Lucas and I'm your project manager. It's my job to make sure your project gets done quickly and professionally. In order to find the right designer for you, please fill out the creative brief by clicking on the link on the right.

Also, feel free to comment here with any questions that you may have."""
  end
  
  def status_label
    status.to_s.gsub("_", " ")
  end

  def need_to_show_popup
    created_at.to_i > 1423629558 && !shown_popup
  end

  def showing_popup
    self.shown_popup = true
    save
  end
end
