class PaymentsController < ApplicationController
  def checkout
    @project         = Project.find(params[:project_id])
    @percent_orig    = params[:percent]
    @percent         = params[:percent].to_f / 100.0
    @amount          = @project.get_price * @percent
    @address         = {}
  end

  def process_payment
    @project         = Project.find(params[:project_id])
    @percent_orig    = params[:percent]
    @percent         = params[:percent].to_f / 100.0
    @amount          = @project.get_price * @percent

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
      redirect_to @project
    rescue Twocheckout::TwocheckoutError => e
      @fname           = params['field-fname']
      @lname           = params['field-lname']
      @company_name    = params['field-company-name']

      @error_message = 'Payment declined: ' + e.message
      render 'checkout'
    end
  end
end
