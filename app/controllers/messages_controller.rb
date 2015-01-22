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
    end

    files = params.select {|a,b| a.to_s.slice(0, 11) == "file-upload"}
    files.map do |key, file|
           attachment = 
             @message.attachments.create({uploaded_date:   DateTime.now,
                                          name:            file.original_filename,
                                          data:            BSON::Binary.new(file.read)})
           attachment.save
         end

    @project.updated_at = DateTime.now
    @project.save

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: @message.serialize_message(request) }
    end
  end

  def view_attachment
    @project = Project.find(params[:project_id])
    if !@project.has_access?(current_user)
      redirect_to_login
    end

    @message    = @project.messages.find(params[:message_id])
    @attachment = @message.attachments.find(params[:attachment_id])
    
    send_data(@attachment.data.data, 
              :type => @attachment.mime,
              :disposition => 'inline')
  end
end
