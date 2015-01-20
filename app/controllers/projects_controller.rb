class ProjectsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :authenticate_user!, only: :new

  def view 
    @project = Project.find(params[:id])
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
    @service = @project.service
    @partial = @service.partial_name
    render "projects/create"
  end

  def archive
    @project = Project.find(params[:id])
    if !current_user.admin
      redirect_to "/"
    else
      @project.status = :closed
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
    @open_projects   = (current_user.admin ? Project.all : current_user.projects)
                       .where(:status.ne => :closed)
                       .order_by(:number.asc)
    @closed_projects = (current_user.admin ? Project.all : current_user.projects)
                       .where(:status => :closed)
                       .order_by(:number.asc)
  end

  def update
    @project = Project.find(params[:project_id])
    @service = @project.service
    
    params.map do |key, val|
            @project.update_answer(key, val)
          end

    @errors = @project.validate_project
    if @errors.length > 0
      render "projects/create"
    else
      @project.save
      redirect_to @project
    end
  end
  
  def new
    if !user_signed_in?
      email = params[:email]
      if User.where(email: email).first
        return authenticate_user!
      else
        @user = User.generate(params[:full_name],
                              params[:email],
                              params[:business_name])
        sign_in(:user, @user)
      end
    else
      @user = current_user
    end

    @service             = Service.where(name: params[:service_name]).first
    @project             = Project.new
    @project.service     = @service
    @project.user        = @user
    @project.status      = :pending
    @project.start_date  = DateTime.now.to_date

    last_project         = @user.projects.order_by(:number.desc).first
    @project.number      = last_project ? last_project.number + 1 : 1

    params.map do |key, val|
            @project.add_answer(key, val)
          end

    @errors = @project.validate_project
    if @errors.length > 0
      render "projects/create"
    else
      @project.save
      @project.initialize_project
      ProjectMailer.new_project_mail(@project).deliver
      redirect_to @project
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
