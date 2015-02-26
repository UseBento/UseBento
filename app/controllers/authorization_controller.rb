class AuthorizationController < WebsocketRails::BaseController
  def authorize
    channel      = WebsocketRails[message[:channel]]
    project_id   = channel.split(":")[1]
    project      = Project.find(project_id)
      
    channel.make_private
    
    if project && project.user == current_user
      accept_channel current_user
    else
      deny_channel({:message => 'authorization failed!'})
    end
  end

  def client_connected
    channel      = WebsocketRails[message[:channel]]
    channel.make_private      
  end
end
      
