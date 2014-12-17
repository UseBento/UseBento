class ProjectsController < ApplicationController
  def view 
    @project = Project.find(params[:id])
  end
  
  def new
    @service = Service.where(name: params[:service_name]).first
    @project = Project.new
    @project.service = @service
    print params.to_s
    params.map do |key, val|
            print [key, val]
            @project.add_answer(key, val)
          end
    @errors = @project.validate_project
    if @errors.length > 0
      render "projects/create"
    else
      @project.save
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
