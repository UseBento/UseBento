class MessageWorker

  def perform(project_id, message_id, user_id)
    @project   = Project.find(project_id)
    @message   = @project.messages.find(message_id)
    puts @project.to_s
    puts @message.to_s
    
    participants = @project.people.select {|p| p.accepted}
    participants.map do |participant|
                  if participant != @message.user
                    ProjectMailer.new_user_message_mail(@message, 
                                                        participant.user, 
                                                        @message.user).deliver
                  end
                end
  end
end
