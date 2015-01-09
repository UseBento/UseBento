class Message
  include Mongoid::Document

  field :body,           type: Text
  field :posted_date,    type: DateTime
  
  belongs_to :user
  belongs_to :project
end
