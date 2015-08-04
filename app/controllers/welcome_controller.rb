class WelcomeController < ApplicationController
  def index
  	redirect_to projects_list_path if user_signed_in?
  end
end
