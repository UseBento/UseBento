class PaymentsController < ApplicationController
  def checkout
    @project         = Project.find(params[:project_id])
    @percent         = params[:percent].to_f / 100.0
    @amount          = @project.get_price * @percent

    
  end
end
