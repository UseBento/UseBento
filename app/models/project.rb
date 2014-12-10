class Project
  include Mongoid::Document
  
  field :start_date,    type: DateTime

  has_one :service
  embeds_many :answers
  validates_associated :answers
  validates :start_date, :presence => true
end
