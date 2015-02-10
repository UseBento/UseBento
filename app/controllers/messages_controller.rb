class MessagesController < ApplicationController
  before_action :authenticate_user!
  
  def post_message
    @project = Project.find(params[:project_id])
    if !@project.has_access?(current_user)
      redirect_to_login
    end

    @message = @project.messages.create({body:  params[:message_body],
                                         posted_date: DateTime.now})
    @message.user = current_user
    @message.save

    if (current_user.admin)
      ProjectMailer.new_admin_message_mail(@message).deliver
    else
      ProjectMailer.new_user_message_mail(@message).deliver
    end

    @project.updated_at = DateTime.now
    @project.save!
    attachments = get_attachments(@message)

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: @message.serialize_message(request) }
    end
  end
end
