class DesignerProfile
  include Mongoid::Document

  field :full_name,           type: String
  field :portfolio_url,       type: String
  field :dribble_url,         type: String
  field :behance_url,         type: String
  field :skill_1,             type: String
  field :skill_2,             type: String
  field :skill_3,             type: String
  field :paypal_email,        type: String
  field :available,           type: Boolean, default: true

  embedded_in :user

  # validates_presence_of :full_name, :portfolio_url

end