class UsersController < Devise::SessionsController
  before_filter :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) { |u| 
      u.permit(:password, :password_confirmation, :current_password) 
    }
  end

  def login_popup
    render 'login', layout: false
  end

  def sign_up_popup
    render 'sign_up', layout: false
  end

  def password_popup
    render 'password', layout: false
  end

  def password_reset_sent_popup
    render 'password_reset_sent', layout: false
  end

  def get_error(name)
    ''
  end

  def profile
    render 'profile', :layout => "application"
  end

  def update_profile
    current_user.email       = params[:email]
    current_user.name        = params[:name]
    current_user.company     = params[:company]
    current_user.save

    @info_success            = "Updated your information"

    if (params[:password] != "")
      if (!current_user.valid_password?(params[:password]))
        @password_errors = "Invalid password"
      else
        if (params[:new_password] != params[:new_password_confirm])
          @password_errors = "Passwords don't match"
        else
          current_user.update_with_password(
              {current_password:      params[:password],
               password:              params[:new_password],
               password_confirmation: params[:new_password_confirm]})
          @password_success = "Updated your password successfully"
        end
      end
    end
    render 'profile', :layout => "application"
  end

  def reset
    error = false
    user = User.where(email: params[:email]).first
    if !user
      error = "Invalid email"
    else
      user.send_reset_password_instructions
    end

    respond_to do |format|
      format.html { redirect_to '/' }
      format.json { 
          if error
            render json: {error: error}
          else
            render json: {}
          end }
    end
  end

  def log_in
    error = false
    user = User.where(email: params[:email]).first
    if (!user)
      error = "Invalid username or password"
    else
      if !user.valid_password?(params[:password])
        error = "Invalid username or password"
      else
        sign_in :user, user
      end
    end

    respond_to do |format|
      format.html { redirect_to '/' }
      format.json { 
          if error
            render json: {error: error}
          else
            render json: {}
          end }
    end
  end

  def sign_up
    existing_user = User.where(email: params[:email]).first
    if !existing_user 
        @user = User.create({email:      params[:email],
                             name:       params[:name],
                             password:   params[:password],
                             company:    params[:company]})
        sign_in(:user, user)
    end

    respond_to do |format|
      format.html { redirect_to '/' }
      format.json { 
          if existing_user
            render json: {error: "A user with that email already exists!"}
          else
            render json: @user 
          end }
    end
  end
end
