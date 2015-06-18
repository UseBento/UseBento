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
  field :company_size,       type: String
  field :admin,              type: Boolean
  field :designer,           type: Boolean, default: false

  


  embeds_one  :designer_profile
  has_many :projects

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
    admin_user   = User.where({admin: true, name: "Bento Bot"}).first
    admin_user   = User.where({admin: true}).first unless admin_user
    admin_user
  end

  def short_email
    if email.length > 20
      email.slice(0,20) + "..."
    else
      email
    end
  end

  def full_name
    if self.designer && self.name.blank?
      self.designer_profile.full_name
    else
      self.name.split.map(&:capitalize).join ' '
    end
  end

  def first_name
    self.name.split.first.capitalize
  end

  def self.generate(name, email, company, company_size)
    password = Devise.friendly_token.first(12)
    user     = User.create({email:        email,
                            name:         name,
                            company:      company,
                            company_size: company_size,
                            password:     password})
    [user, password]
  end

  def self.default_avatar_for(name)
    "/images/avatars/" + name[0].upcase + ".png"
  end

  def avatar(root_domain)
    if self.admin
      return "/images/chat_new.png"
    end

    hash = Digest::MD5.hexdigest(self.email.strip.downcase)
    if self.designer
      default_img = URI.encode_www_form_component(
                    "https://" + root_domain + User.default_avatar_for(self.designer_profile.full_name))
    else
      default_img = URI.encode_www_form_component(
                    "https://" + root_domain + User.default_avatar_for(name))
    end
    
    "//secure.gravatar.com/avatar/" + hash + "?d=" + default_img
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

  def accessible_projects
    Project.or({"user_id" => id},
               {"invited_users.user_id" => id},
               {"invited_designers.user_id" => id})
  end

  def designer_projects
    Project.where({"invited_designers.user_id" => id})
  end
end
