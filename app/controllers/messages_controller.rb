class MessagesController < ApplicationController
  before_action :authenticate_user!
  
  def post_message
    @project = Project.find(params[:project_id])
    @message = @project.messages.create({body:  params[:message_body],
                                         posted_date: DateTime.now})
    @message.user = current_user
    @message.save

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: @message }
    end
  end
end
