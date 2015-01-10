class Message
  include Mongoid::Document

  field :body,           type: String
  field :posted_date,    type: DateTime
  
  belongs_to :user
  embedded_in :project
end
