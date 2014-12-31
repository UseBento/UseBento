class ProjectsController < ApplicationController
  def view 
    @project = Project.find(params[:id])
  end

  def list
    @open_projects   = current_user.projects
                       .where(:status.ne => :closed)
                       .order_by(:number.asc)
    @closed_projects = current_user.projects
                       .where(:status => :closed)
                       .order_by(:number.asc)
  end
  
  def new
    @service           = Service.where(name: params[:service_name]).first
    @project           = Project.new
    @project.service   = @service
    @project.user      = current_user
    @project.status    = :pending

    last_project       = current_user.projects.order_by(:number.desc).first
    @project.number    = last_project ? last_project.number + 1 : 1

    params.map do |key, val|
            @project.add_answer(key, val)
          end

    @errors = @project.validate_project
    if @errors.length > 0
      render "projects/create"
    else
      @project.save
      ProjectMailer.new_project_mail(@project)
      redirect_to @project
    end
  end

  def get_error(name)
    filtered = @errors.select do |error|
                        error[:question].name == name
                      end
    if filtered.length == 0
      "ff"
    else
      filtered[0][:message]
    end
  end
  helper_method :get_error
end
