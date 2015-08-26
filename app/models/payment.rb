class Payment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount,          type: Integer
  field :raw_response,    type: Hash
  field :transaction_id,  type: Integer
  field :response_code,   type: String
  
  belongs_to :project
  belongs_to :user

  def self.api_credentials
    {private_key:      Rails.configuration.twocheckout_private_key,
     seller_id:        Rails.configuration.twocheckout_seller_id.to_s,
     sandbox:          Rails.configuration.twocheckout_sandbox}
  end

  
  
  def self.new_payment(project, amount, token, address) 
    Twocheckout::API.credentials = self.api_credentials
    payment = Payment.new

    params  = {token:           token,
               merchantOrderId: payment.id.to_s,
               currency:        'USD',
               total:           amount.to_s,
               billingAddr:     address}
    begin
      if Rails.configuration.twocheckout_sandbox 
        Twocheckout::Checkout.sandbox(true);
      end
      result = Twocheckout::Checkout.authorize(params)
      payment.amount           = amount
      payment.raw_response     = result
      payment.transaction_id   = result["orderNumber"]
      payment.response_code    = result["responseCode"]
      payment.project          = project
      payment.save

      project.updated_at       = DateTime.now
      project.status           = :in_progress       if project.status == :pending
      project.save
    rescue Twocheckout::TwocheckoutError => e
      raise e
    end
  end
end
