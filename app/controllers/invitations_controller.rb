class InvitationsController < ApplicationController
  def join
    @project       = Project.find(params[:project_id])
    @invitation    = @project.invited_users.find(params[:id])
    
    if not @invitation or not @project
      return
    end

    if @invitation.user
      @invitation.accepted = true
      @invitation.save
      
      redirect_to @project
    else
      if current_user
        @invitation.user       = current_user
        @invitation.accepted   = true
        @invitation.save

        redirect_to @project
      else
        session[:user_return_to] = request.fullpath
        redirect_to "/users/sign_up"
      end
    end
  end
end
