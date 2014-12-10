class Service
  include Mongoid::Document
  field :name,            type: String
  field :title,           type: String
  field :description,     type: String
  field :rounds,          type: Integer
  field :completion_time, type: Range
  field :price,           type: Integer

  embeds_many :questions
end
