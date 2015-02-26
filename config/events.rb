WebsocketRails::EventMap.describe do
  namespace :chat do
      subscribe :client_connected, :to => ChatController, :with_method => :connected
  end 


  class AuthorizationController < WebsocketRails::BaseController
    def authorize
      channel      = WebsocketRails[message[:channel]]
      project_id   = channel.split(":")[1]
      project      = Project.find(project_id)

      if project && project.user == current_user
        accept_channel current_user
      else
        deny_channel({:message => 'authorization failed!'})
      end
    end
  end
      
  subscribe :subscribe, :to => AuthorizationController, :with_method => :authorize

  # You can use this file to map incoming events to controller actions.
  # One event can be mapped to any number of controller actions. The
  # actions will be executed in the order they were subscribed.
  #
  # Uncomment and edit the next line to handle the client connected event:
  #   subscribe :client_connected, :to => Controller, :with_method => :method_name
  #
  # Here is an example of mapping namespaced events:
  #   namespace :product do
  #     subscribe :new, :to => ProductController, :with_method => :new_product
  #   end
  # The above will handle an event triggered on the client like `product.new`.

end
