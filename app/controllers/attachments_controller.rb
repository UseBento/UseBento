class AttachmentsController < ApplicationController
  before_action :authenticate_user!

  def view_attachment
    @project = Project.find(params[:project_id])
    if !@project.has_access?(current_user)
      redirect_to_login
    end

    if (params[:message_id])
      @message    = @project.lookup_message(params[:message_id])
      @attachment = @message.attachments.find(params[:attachment_id])
    else
      @attachment = @project.attachments.find(params[:attachment_id])
    end

    send_data(@attachment.attachment.read,
              :type          => @attachment.mime,
              :disposition   => 'inline')
  end
end
