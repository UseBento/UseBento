class AwaitingPayment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount,     type: Integer
  field :paid,       type: Boolean
  
  belongs_to :project
  
end
