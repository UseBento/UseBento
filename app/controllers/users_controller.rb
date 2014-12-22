class UsersController < ApplicationController
  def login
    render 'login', layout: false
  end

  def sign_up
    render 'sign_up', layout: false
  end

  def password
    render 'password', layout: false
  end

  def password_reset_sent
    render 'password_reset_sent', layout: false
  end
end
