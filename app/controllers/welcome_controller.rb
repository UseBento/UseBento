class WelcomeController < ApplicationController
  def index
  	if user_signed_in?
  		redirect_to projects_list_path 
  	else
  		render layout: "application_new"
  	end
  end

  def privacy
  	render layout: "application_new"
  end

  def products_pricing
  	render layout: "application_new"
  end

  def terms
  	render layout: "application_new"
  end

  def whitepapers
  	render layout: "application_new"
  end
end
