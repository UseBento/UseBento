class ServicesController < ApplicationController
  def select
  end

  def create
    name = params[:name]
    @service = Service.where(name: name).first
    @partial = @service.partial_name
    render "projects/create"
  end

  def add
  end
end
