class ProjectsController < ApplicationController
  def view 
  end
  
  def new
    service = Service.where(name: params[:service_name]).first
    @project = Project.new
    @project.service = service
    params.map do |key, val|
            @project.add_answer(key, val) 
          end
    @project.save
  end
end
