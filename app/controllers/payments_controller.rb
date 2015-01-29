class PaymentsController < ApplicationController
  protect_from_forgery :except => [:process_pp_payment]

  def checkout
    @project         = Project.find(params[:project_id])
    #@amount          = params[:amount]
    @amount           = @project.awaiting_payments.first.amount
    @percent         = @amount.to_f / @project.get_price.to_f
    @percent_orig    = @percent * 100.0
    @address         = {}
  end

  def process_payment
    @project         = Project.find(params[:project_id])
    @amount          = params[:amount]
    @amount          = @project.awaiting_payments.first.amount
    @percent         = @amount.to_f / @project.get_price.to_f
    @percent_orig    = @percent * 100.0

    token            = params[:twocheckout_token]
    @address         = {name:         (params['field-fname'] + ' ' + 
                                       params['field-lname']),
                        addrLine1:     params['field-addr'],
                        addrLine2:     params['field-addr2'],
                        city:          params['field-city'],
                        state:         params['field-state'],
                        zipCode:       params['field-zip'],
                        country:       params['field-country'],
                        email:         params['field-e-mail'],
                        phoneNumber:   params['field-phone-number']}
    
    begin
      Payment.new_payment(@project, @amount, token, @address)
      @project.awaiting_payments.first.delete
      redirect_to @project
    rescue Twocheckout::TwocheckoutError => e
      @fname           = params['field-fname']
      @lname           = params['field-lname']
      @company_name    = params['field-company-name']

      @error_message = 'Payment declined: ' + e.message
      render 'checkout'
    end
  end
  
  def process_pp_payment
    logger.debug params
    hash = Digest::MD5.hexdigest("tango" + 
                                 (Rails.configuration.twocheckout_seller_id.to_s) +
                                 params[:order_number] +
                                 params[:total].to_s).upcase
    if (hash != params[:key])
#      raise "Key doesn't match"
    end
    
    @project               = Project.find(params[:li_0_product_id])
    unpaid_payment         = @project.awaiting_payments.first
    amount                 = params[:total]
    payment                = Payment.new
    payment.amount         = amount
    payment.raw_response   = params
    payment.transaction_id = params[:order_number]
    payment.response_code  = ""
    payment.project        = @project
    payment.save

    @project.awaiting_payments.first.delete
    @project.updated_at    = DateTime.now
    @project.save
    
    redirect_to @project
    # http://localhost:3000/return?middle_initial=&li_0_name=invoice123&sid=1817037&ship_zip=43235&key=5B4A034987D9FDA6BF2871700D1A6881&state=OH&email=example%402co.com&li_0_type=product&order_number=205484030789&currency_code=USD&lang=en&ship_state=OH&invoice_id=205484030798&li_0_price=25.99&total=25.99&ship_street_address2=Apartment+123&credit_card_processed=Y&zip=43228&ship_name=Gift+Receiver&li_0_quantity=1&ship_method=&cart_weight=0&fixed=Y&ship_country=USA&last_name=Shopper&li_0_product_id=&street_address=123+Test+Address&city=Columbus&li_0_tangible=&ship_city=Columbus&country=USA&ip_country=United+States&merchant_order_id=&li_0_description=&ship_street_address=1234+Address+Road&demo=Y&pay_method=CC&cart_tangible=N&phone=3333333333+&street_address2=Suite+200&first_name=Checkout&card_holder_name=Checkout+Shopper
    # #http://localhost:3000/return?
    # middle_initial=
    # li_0_name=invoice123
    # sid=1817037
    # ship_zip=43235
    # key=5B4A034987D9FDA6BF2871700D1A6881
    # state=OH
    # email=example%402co.com
    # li_0_type=product
    # order_number=205484030789
    # currency_code=USD
    # lang=en
    # ship_state=OH
    # invoice_id=205484030798
    # li_0_price=25.99
    # total=25.99
    # ship_street_address2=Apartment+123
    # credit_card_processed=Y
    # zip=43228
    # ship_name=Gift+Receiver
    # li_0_quantity=1
    # ship_method=
    # cart_weight=0
    # fixed=Y
    # ship_country=USA
    # last_name=Shopper
    # li_0_product_id=
    # street_address=123+Test+Address
    # city=Columbus
    # li_0_tangible=
    # ship_city=Columbus
    # country=USA
    # ip_country=United+States
    # merchant_order_id=
    # li_0_description=
    # ship_street_address=1234+Address+Road
    # demo=Y
    # pay_method=CC
    # cart_tangible=N
    # phone=3333333333+
    # street_address2=Suite+200
    # first_name=Checkout
    # card_holder_name=Checkout+Shopper
  end
end
