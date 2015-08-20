class ProjectsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cache_headers, only: [:list, :view]
  skip_before_action :authenticate_user!, only: [:new, :join, :start, :finish_start]

  def update_can_see
    project   = Project.find(params[:pid])
    user      = User.find(params[:uid])

    project.set_can_see_invoice(user, params[:can] == 'true')

    respond_to do |format|
      format.html { redirect_to project }
      format.json { render :json => project.can_see_invoice }
    end    
  end

  def start
    @service = params[:service]
    @is_project_start = true
  end

  def finish_start
    @type       = params[:project_type]
    @service    = Service.where(name: params[:service]).first
    @errors     = []
    @project    = Project.new
    @project.service     = @service
    # @service_json = @service.to_json


    if params[:login_email_address]
      @user = User.where(email: params[:login_email_address]).first
      if !@user || !@user.valid_password?(params[:login_password])
        @error = "Invalid username or password"
        return render 'projects/start', layout: 'application'
      end
      sign_in @user
      sign_in @user, :bypass => true
    elsif params[:signup_email_address]      
      @user, password = User.generate(params[:signup_full_name],
                                      params[:signup_email_address],
                                      params[:signup_company],
                                      params[:signup_company_size])
      sign_in @user
      sign_in @user, :bypass => true
      UserMailer.new_generated_user_mail(@user, password, false).deliver
    end
    
    # render :
    # render :format => 'js' { :}
    
  end

  def submit_start
    @user                    = current_user
    @service                 = Service.where(name: params[:service_name]).first
    @project                 = Project.new
    @project.total_price     = 0
    @project.service         = @service
    @project.project_type    = params[:project_type]
    @project.status          = :pending
    @project.start_date      = DateTime.now.to_date
    if current_user.company
      last_project         = Project.where(company: Project.normalize_company(
                                              current_user.company))
                             .order_by(:number.desc).first
      @project.number      = last_project ? last_project.number + 1 : 1
    else
      @project.number = 1
    end
    
    @project.add_answer(:business_name, current_user.company || current_user.name)
    @project.add_answer(:email, current_user.email)
    @project.add_answer(:full_name, current_user.full_name)
    @project.add_answer(:project_name, params[:project_name])
    @project.add_answer(:business_description, params[:business_description])
    @project.add_answer(:project_deadline, params[:project_deadline])


    if not params[:pages].blank?
      @project.add_answer(:pages, params[:pages])
      @project.add_answer(:design_andor_development, params[:design_andor_development])
    else
      @project.add_answer(:pages, params[:pages])
      @project.add_answer(:design_andor_development, params[:design_andor_development])
    end
    @project.user = @user
    @project.save
    
    @project.update_company
    @project.initialize_project

    # ProjectMailer.new_project_mail(@project).deliver
    # mail send to admin users
    admin_list = User.get_admin_list
    if not admin_list.blank?
      admin_list.each do |admin_user|
        ProjectMailer.new_project_mail_to_admin(@project, admin_user).deliver
      end
    end


    @project.people
    @project.set_default_price
    redirect_to @project
  end

  def view
    @project = Project.find(params[:id])
    @project.get_awaiting_payments
    @project_statuses = Project::STATUS_LIST

    @chat     = :group
    @editing  = false
    @messages = @project.messages
    @is_show_available = true
    @designers = User.where(:designer => true)

    
    if !@project.has_access?(current_user)
      invite = @project.was_invited?(current_user)
      if invite
        invite.accepted = true
        invite.save
      else
        # return redirect_to_login
        invite_designer = @project.was_designer_invited?(current_user)
        if invite_designer
          invite_designer.accepted = true
          invite_designer.save
        else
          return redirect_to_login
        end
      end
    end

    @is_show_designers_li = false
    @project.designers.each do |designer|
      if designer.can_see?(current_user)
        @is_show_designers_li = true
        break  
      end
    end
  end

  def private_chat
    @project = Project.find(params[:id])
    @project.get_awaiting_payments
    @project_statuses = Project::STATUS_LIST

    @chat     = :private
    @editing  = false
    @messages = @project.get_private_chat.messages
    @designers = User.where(:designer => true)

    if !@project.has_access?(current_user)
      invite = @project.was_invited?(current_user)
      if invite
        invite.accepted = true
        invite.save
      else
        # return redirect_to_login
        invite_designer = @project.was_designer_invited?(current_user)
        if invite_designer
          invite_designer.accepted = true
          invite_designer.save
        else
          return redirect_to_login
        end
      end
      
    end

    render "projects/view"
  end

  def edit
    @project = Project.find(params[:id])
    if !@project.has_access?(current_user)
      return redirect_to_login
    end

    @errors  = []
    @editing = true
    @service = @project.service
    @partial = @service.partial_name
    render "projects/create"
  end

  def view_creative_projects
    @project = Project.find(params[:id])
    if !@project.has_access?(current_user)
      return redirect_to_login
    end

    @errors  = []
    @editing = false
    @service = @project.service
    @partial = @service.partial_name
    render "projects/view_creative"
  end

  def archive
    @project = Project.find(params[:id])
    if !current_user.admin
      redirect_to "/"
    else
      @project.last_status    = @project.status
      @project.status         = :closed
      @project.save
      redirect_to "/projects/list"
    end
  end

  def unarchive
    @project = Project.find(params[:id])
    if !current_user.admin
      redirect_to "/"
    else
      @project.status         = @project.last_status
      @project.save
      redirect_to "/projects/list"
    end
  end

  def delete
    @project = Project.find(params[:id])
    if !current_user.admin
      redirect_to "/"
    else
      @project.destroy
      redirect_to "/projects/list"
    end
  end

  def list
    @open_projects   = (current_user.admin ? Project.all : current_user.accessible_projects)
                       .where(:status.ne => :closed)
                       .order_by(:number.asc)
    @closed_projects = (current_user.admin ? Project.all : current_user.accessible_projects)
                       .where(:status => :closed)
                       .order_by(:number.asc)

    
    @is_show_available = current_user.designer
  end

  def update
    @project     = Project.find(params[:project_id])
    @service     = @project.service
    filled_out   = @project.filled_out_creative_brief?
    get_attachments(@project)

    # binding.pry

    params.map do |key, val|
      @project.update_answer(key, val)
    end
    @errors = @project.validate_project
    if @errors.length > 0
      render "projects/create"
    else
      if !filled_out && @project.filled_out_creative_brief?
        # Update project status if a creative brief was filled out
        status_index = Hash[Project::STATUS_LIST.map.with_index.to_a]
        brief_index = status_index['Creative Brief']
        if brief_index > @project.status_index
          @project.status_index = brief_index
        end
      end
      @project.set_update_price
      @project.save
      @project.update_company
      redirect_to @project
    end
  end

  def update_status
    @project = Project.find(params[:project_id])
    status = params[:status].to_i


    # if !current_user.admin || !@project.was_designer_invited?(current_user) || status < 0
    #   return render :nothing => true, :status => 500
    # end

    if status < 0
      return render :nothing => true, :status => 500
    elsif !current_user.admin && !@project.was_designer_invited?(current_user)
      return render :nothing => true, :status => 500
    end

    # Clicking on the current status will unselect it
    if @project.status_index == status
      @project.status_index = status - 1
    else
      @project.status_index = status
    end

    if @project.save
      @project.people.each do |person|
        unless person.user == current_user
          to_first_name = person.first_name
          from_full_name = current_user.full_name
          to_email = person.email
          ProjectMailer.project_status_update_mail(@project, to_first_name, from_full_name, to_email).deliver
        end
      end

      @project.designers.each do |designer|
        unless designer.user == current_user
          to_first_name = designer.first_name
          from_full_name = current_user.full_name
          
          to_email = designer.email
          ProjectMailer.project_status_update_mail(@project, to_first_name, from_full_name, to_email).deliver
        end
      end
      
    end

    redirect_to @project
  end

  def new
    return self.update if params[:editing]

    @service             = Service.where(name: params[:service_name]).first
    @project             = Project.new
    @project.service     = @service
    @project.status      = :pending
    @project.start_date  = DateTime.now.to_date

    last_project         = Project.where(company: Project.normalize_company(
                                            params[:business_name]))
                           .order_by(:number.desc).first
    @project.number      = last_project ? last_project.number + 1 : 1

    params.map do |key, val|
            @project.add_answer(key, val)
          end

    @errors = @project.validate_project
    if @errors.length > 0

      render "projects/create"
    else
      existing_user = user_signed_in?
      if !existing_user
        email = params[:email]
        if User.where(email: email).first
          return authenticate_user!
        else
          @user, password = User.generate(params[:full_name],
                                          params[:email],
                                          params[:business_name])
          sign_in @user
          sign_in @user, :bypass => true
        end
      else
        @user = current_user
      end

      @project.user = @user
      @project.save
      @project.update_company
      @project.initialize_project


      # ProjectMailer.new_project_mail(@project).deliver
      # mail send to admin users
      admin_list = User.get_admin_list
      if not admin_list.blank?
        admin_list.each do |admin_user|
          ProjectMailer.new_project_mail_to_admin(@project, admin_user).deliver
        end
      end


      if !existing_user
        UserMailer.new_generated_user_mail(@user, password, @project).deliver
      end

      redirect_to @project
    end
  end

  def remove_payment
    if !current_user.admin
      redirect_to "/"
    else
      @project  = Project.find(params[:project_id])
      @project.remove_payment

      respond_to do |format|
        format.html { redirect_to @project }
        format.json { render :json => @project }
      end
    end
  end
  
  def update_total_price
    if !current_user.admin
      redirect_to "/"
    else
      @project             = Project.find(params[:project_id])
      @project.total_price = params[:amount]
      @project.status = :in_progress
      @project.save
      @project.get_awaiting_payments

      
      respond_to do |format|
        format.html { redirect_to @project }
        format.json { render :json => @project }
      end
    end
  end

  def update_payment
    return self.update_total_price if params[:id] == 'total'
    if !current_user.admin
      redirect_to "/"
    else
      @project        = Project.find(params[:project_id])
      @payment        = @project.awaiting_payments.find(params[:id])
      price           = @project.get_price + (params[:amount].to_i - @payment.amount)
      @project.total_price = price
      @project.save

      @payment.amount = params[:amount]
      @payment.save

      
      respond_to do |format|
        format.html { redirect_to @project }
        format.json { render :json => @project }
      end
    end
  end

  def invite
    @project    = Project.find(params[:id])

    invitation = InvitedUser.send_invite(@project, current_user, params[:email])
    @error     = invitation if invitation.class != InvitedUser

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render :json => @error ? {error: @error} : invitation }
    end
  end

  def invite_designer
    @project    = Project.find(params[:id])

    invitation = InvitedDesigner.send_invite(@project, current_user, params[:email])
    @error     = invitation if invitation.class != InvitedDesigner

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render :json => @error ? {error: @error} : invitation }
    end
  end

  def invite_to_private
    @project        = Project.find(params[:id])
    @private_chat   = @project.private_chat

    invitation = InvitedUser.send_invite(@private_chat, current_user, params[:email])
    @error     = invitation if invitation.class != InvitedUser

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render :json => @error ? {error: @error} : invitation }
    end
  end

  def invite_designer_to_private
    @project        = Project.find(params[:id])
    @private_chat   = @project.private_chat

    invitation = InvitedDesinger.send_invite(@private_chat, current_user, params[:email])
    @error     = invitation if invitation.class != InvitedDesinger

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render :json => @error ? {error: @error} : invitation }
    end
  end

  def initial_popup
    @project = Project.find(params[:id])
    render 'initial_popup', layout: false
  end

  def remove_invite
    @project = Project.find(params[:id])
    invite   = @project.invited_users.find(params[:invite_id]) || @project.private_chat.invited_users.find(params[:invite_id])
    if (invite.can_delete?(current_user))
      invite.delete
    end
    respond_to do |format|
      format.html { render json: {success: true}}
    end
  end

  def remove_invite_designer
    @project = Project.find(params[:id])
    invite_designer   = @project.invited_designers.find(params[:invite_id]) || @project.private_chat.invited_designers.find(params[:invite_id])
    if (invite_designer.can_delete?(current_user))
      invite_designer.delete
    end
    respond_to do |format|
      format.html { render json: {success: true}}
    end
  end

  def get_error(name)
    filtered = @errors.select do |error|
                        error[:question].name == name
                      end
    if filtered.length == 0
      ""
    else
      filtered[0][:message]
    end
  end
  helper_method :get_error

  private

  def set_cache_headers
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end
end
