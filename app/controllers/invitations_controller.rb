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
      if !@project.project.has_access?(@invitation.user)
        invitation  = @project.project.invited_users.create({accepted:   false,
                                                             email:      @invitation.email})
        invitation.inviter_id  = @invitation.inviter_id
        invitation.user        = @invitation.user
        invitation.accepted    = true
        invitation.save
      end
      redirect_to '/projects/' + @project.project.id + '/private_chat'
    else
      redirect_to @project
    end
  end

  def join_designer
    @project       = Project.find(params[:project_id])
    @project       = @project.private_chat if params[:chat] == 'private'
    @invitation    = @project.invited_designers.find(params[:id])

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
      if !@project.project.has_access?(@invitation.user)
        invitation  = @project.project.invited_designers.create({accepted:   false,
                                                             email:      @invitation.email})
        invitation.inviter_id  = @invitation.inviter_id
        invitation.user        = @invitation.user
        invitation.accepted    = true
        invitation.save
      end
      redirect_to '/projects/' + @project.project.id + '/private_chat'
    else
      redirect_to @project
    end
  end
end
