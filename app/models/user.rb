class User
  include Mongoid::Document
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  ## Database authenticatable
  field :email,              type: String, default: ""
  field :encrypted_password, type: String, default: ""

  ## Recoverable
  field :reset_password_token,   type: String
  field :reset_password_sent_at, type: Time

  ## Rememberable
  field :remember_created_at, type: Time

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  field :name,               type: String
  field :company,            type: String
  field :admin,              type: Boolean

  ## Confirmable
  # field :confirmation_token,   type: String
  # field :confirmed_at,         type: Time
  # field :confirmation_sent_at, type: Time
  # field :unconfirmed_email,    type: String # Only if using reconfirmable

  ## Lockable
  # field :failed_attempts, type: Integer, default: 0 # Only if lock strategy is :failed_attempts
  # field :unlock_token,    type: String # Only if unlock strategy is :email or :both
  # field :locked_at,       type: Time

  def self.get_admin
    self.where(admin: true).first
  end

  has_many :projects

  def full_name
    self.name.split.map(&:capitalize).join ' '
  end

  def self.generate(name, email, company) 
    password = Devise.friendly_token.first(12)
    user     = User.create({email:        email,
                            name:         name,
                            company:      company,
                            password:     password})
    [user, password]
  end

  def avatar(root_domain)
    if self.admin
      return "/images/chat.png"
    end

    hash = Digest::MD5.hexdigest(self.email.strip.downcase)
    default_img = URI.encode_www_form_component(
                    root_domain + "/images/default_avatar.gif")
    "http://www.gravatar.com/avatar/" + hash + "?d=" + default_img
  end
  
  def last_project
    self.projects.last
  end

  def default_keywords
    project = last_project
    project ? project.answer_for('business_keywords').answer : ""
  end

  def default_target_audience
    project = last_project
    project ? project.answer_for('target_audience').answer : ""
  end
end
