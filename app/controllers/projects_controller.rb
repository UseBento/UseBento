class ProjectsController < ApplicationController
  before_action :authenticate_user!

  def view 
    @project = Project.find(params[:id])
    if !@project.has_access?(current_user)
      redirect_to_login
    end
  end

  def edit
    @project = Project.find(params[:id])
    if !@project.has_access?(current_user)
      redirect_to_login
    end
    
    @errors  = []
    @service = @project.service
    @partial = @service.partial_name
    render "projects/create"
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
    @service             = Service.where(name: params[:service_name]).first
    @project             = Project.new
    @project.service     = @service
    @project.user        = current_user
    @project.status      = :pending
    @project.start_date  = DateTime.now.to_date

    last_project         = current_user.projects.order_by(:number.desc).first
    @project.number      = last_project ? last_project.number + 1 : 1

    params.map do |key, val|
            @project.add_answer(key, val)
          end

    @errors = @project.validate_project
    if @errors.length > 0
      render "projects/create"
    else
      @project.save
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
