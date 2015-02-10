class ProjectsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: [:new, :join]

  def view 
    @project = Project.find(params[:id])
    @project.get_awaiting_payments
    @editing = false
    if !@project.has_access?(current_user)
      return redirect_to_login
    end
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
  end

  def update
    @project = Project.find(params[:project_id])
    @service = @project.service
    get_attachments(@project)
    
    params.map do |key, val|
            @project.update_answer(key, val)
          end

    @errors = @project.validate_project
    if @errors.length > 0
      render "projects/create"
    else
      @project.save
      @project.update_company
      redirect_to @project
    end
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
      
      ProjectMailer.new_project_mail(@project).deliver
      if !existing_user
        UserMailer.new_generated_user_mail(@user, password, @project).deliver
      end
      redirect_to @project
    end
  end

  def update_total_price
    if !current_user.admin
      redirect_to "/"
    else
      @project             = Project.find(params[:project_id])
      @project.total_price = params[:amount]
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
    email       = params[:email]
    user        = User.where(email: email).first
    
    invitation  = @project.invited_users.create({accepted:   false,
                                                 email:      email})
    invitation.inviter = current_user

    if user
      invitation.user = user
      invitation.save
    end
    
    UserMailer.invited_to_project_mail(invitation, @project, current_user).deliver

    respond_to do |format|
      format.html { redirect_to @project }
      format.json { render :json => invitation }
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
end
