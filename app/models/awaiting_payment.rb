class AwaitingPayment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount,     type: Integer
  field :paid,       type: Boolean
  
  belongs_to :project
  

  def as_json(i=0)
    {
      payment_id: self.id,
      amount:   self.amount
    }
  end
  
end
