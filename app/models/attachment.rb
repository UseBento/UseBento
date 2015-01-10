class Attachment
  include Mongoid::Document
  
  field :uploaded_date,    type: DateTime
  field :name,             type: String
  field :data,             type: BSON::Binary

  embedded_in :message
end
