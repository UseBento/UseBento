class ServicesController < ApplicationController
  def select
  end

  def create
    name = params[:name]
    @service = Service.where(name: name).first
    @partial = @service.partial_name
    @project = Project.new
    render "projects/create"
  end
  
  def add
  end

  def get_error(name)
    ""
  end
  helper_method :get_error
end
