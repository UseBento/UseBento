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

  def view_attachment
    @project = Project.find(params[:project_id])
    if !@project.has_access?(current_user)
      redirect_to_login
    end

    @message    = @project.messages.find(params[:message_id])
    @attachment = @message.attachments.find(params[:attachment_id])
    
    send_data(@attachment.attachment.read, 
              :type          => @attachment.mime,
              :disposition   => 'inline')
  end

  def update
    @project     = Project.find(params[:project_id])
    message      = @project.messages.find(params[:id])

    return redirect_to @project if !(message.user == current_user || current_user.admin)
      
    new_message  = params[:new_message]
    message.body = new_message
    message.save

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: {body: message.body_as_html(false, false),
                                  raw:  new_message,
                                  id:   message.id.to_s} }
    end
  end

  def remove
    @project     = Project.find(params[:project_id])
    message      = @project.messages.find(params[:id])
    return redirect_to @project if !(message.user == current_user || current_user.admin)
    message.delete

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: {success: true}}
    end
  end
end
