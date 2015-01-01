class Payment
  include Mongoid::Document
  include Mongoid::Timestamps

  field :amount,          type Integer
  field :raw_response,    type Hash
  field :transaction_id,  type Integer
  field :response_code,   type String
  
  belongs_to :project
  belongs_to :user

  def self.api_credentials
    {private_key:      Rails.configuration.twocheckout_private_key,
     seller_id:        Rails.configuration.twocheckout_seller_id,
     sandbox:          true}
  end
  
  def self.new_payment(project, amount, token, address) 
    Twocheckout::API.credentials = self.api_credentials

    params  = {token:           token,
               currency:        'USD',
               total:           amount.to_s,
               billingAddr:     address}
    begin
      result = Twocheckout::Checkout.authorize(params)
      payment = Payment.create({amount:           aount,
                                raw_response:     result,
                                transaction_id:   result["orderNumber"],
                                response_code:    result["responseCode"]})
    rescue Twocheckout::TwocheckoutError => e
      puts e.message
      false
    end
  end
end
