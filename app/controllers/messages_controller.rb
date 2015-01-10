class MessagesController < ApplicationController
  before_action :authenticate_user!
  
  def post_message
    @project = Project.find(params[:project_id])
    @message = @project.messages.create({body:  params[:message_body],
                                         posted_date: DateTime.now})
    @message.user = current_user
    @message.save

    files = params.select {|a,b| a.to_s.slice(0, 11) == "file-upload"}
    files.map do |key, file|
           attachment = 
             @message.attachments.create({uploaded_date:   DateTime.now,
                                          name:            file.original_filename,
                                          data:            BSON::Binary.new(file.read)})
           attachment.save
         end

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render json: @message.serialize_message(request) }
    end
  end
end
