class MessagesController < ApplicationController
  before_action :authenticate_user!

  def post_message
    @project = Project.find(params[:project_id])
    if !@project.has_access?(current_user)
      redirect_to_login
    end

    @project.updated_at = DateTime.now
    @project.save

    @room     = params['chat-room'];
    @people   = @room == 'private' ? @project.get_private_chat.people : @project.people
    @designers = @project.designers
    @messages = @room == 'private' ? @project.get_private_chat.messages : @project.messages
    @message  = @messages.create({body:  params[:message_body],
                                  posted_date: DateTime.now})
    @message.user = current_user
    @message.save

    attachments  = get_attachments(@message)

    message_body = render_to_string(partial:   'projects/message',
                                    layout:     false,
                                    formats:    :html,
                                    locals:    {message:  @message,
                                                to_owner: true})
    url          = root_url + ('/projects/' + @project.id +
                    (@room == 'private' ? '/private_chat' : ''))

    @message.send_emails(current_user, url, @room)
    @project.updated_at = DateTime.now
    @project.save!


    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: @message.serialize_message(request, message_body) }
    end
  end

  def view
    @project = Project.find(params[:project_id])
    if (!@project.has_access?(current_user))
      redirect_to_login
    end

    @message = @project.lookup_message(params[:message_id])
    message_body = render_to_string(partial:   'projects/message',
                                    layout:     false,
                                    formats:    :html,
                                    locals:    {message:  @message,
                                                to_owner: true})
    serialized = @message.serialize_message(request, message_body)

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: @message.serialize_message(request, message_body) }
    end
  end

  def view_attachment
    @project = Project.find(params[:project_id])
    if !@project.has_access?(current_user)
      redirect_to_login
    end

    @message    = @project.lookup_message(params[:message_id])
    @attachment = @message.attachments.find(params[:attachment_id])

    send_data(@attachment.attachment.read,
              :type          => @attachment.mime,
              :disposition   => 'inline')
  end

  def update
    @project     = Project.find(params[:project_id])
    message      = @project.messages.find(params[:id]) || @project.private_chat.messages.find(params[:id])

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
    message      = @project.messages.find(params[:id]) || @project.private_chat.messages.find(params[:id])
    return redirect_to @project if !(message.user == current_user || current_user.admin)
    message.delete

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: {success: true}}
    end
  end
end
