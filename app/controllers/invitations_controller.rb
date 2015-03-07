class InvitationsController < ApplicationController
  def join
    @project       = Project.find(params[:project_id])
    @project       = @project.private_chat if params[:chat] == 'private'
    @invitation    = @project.invited_users.find(params[:id])

    if not @invitation or not @project
      return
    end

    if @invitation.user
      @invitation.accepted = true
      @invitation.save
    else
      if current_user
        @invitation.user       = current_user
        @invitation.accepted   = true
        @invitation.save
      else
        session[:user_return_to] = request.fullpath
        return redirect_to "/users/sign_up"
      end
    end

    if params[:chat] == 'private'
      redirect_to '/projects/' + @project.project.id + '/private_chat'
    else
      redirect_to @project
    end
  end
end
