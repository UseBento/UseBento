class UsersController < Devise::SessionsController
  before_filter :configure_permitted_parameters, if: :devise_controller?

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:account_update) { |u| 
      u.permit(:password, :password_confirmation, :current_password) 
    }
  end

  def login_popup
    @saved_email = cookies[:saved_email]
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
    @is_show_available = current_user.designer
    render 'profile', :layout => "application"
  end

  def update_profile

    current_user.email       = params[:email]
    if current_user.designer
      current_user.designer_profile.full_name = params[:name]
      current_user.designer_profile.paypal_email = params["paypal-email"]
      current_user.designer_profile.portfolio_url = params[:portfolio]
      current_user.designer_profile.dribble_url = params[:dribble]
      current_user.designer_profile.behance_url = params[:behance]
      current_user.designer_profile.skill_1 = params[:skill_1]
      current_user.designer_profile.skill_2 = params[:skill_2]
      current_user.designer_profile.skill_3 = params[:skill_3]
      # binding.pry
      current_user.save

      @info_success            = "Updated your information"

    else
      
      current_user.name        = params[:name]
      current_user.company     = params[:company]
      current_user.save

      @info_success            = "Updated your information"

    end
    
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

  def exists
    user = User.where(email: params[:email]).first
    respond_to do |format|
      format.html { redirect_to '/' }
      format.json { 
          if user
            render json: {exists: true}
          else
            render json: {exists: false}
          end }
    end
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

  def save_login(email) 
    cookies[:saved_email] = {value: email, 
                             expires: 2.weeks.from_now}
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

    save_login(params[:email])
    # binding.pry

    respond_to do |format|
      format.html { redirect_to '/' }
      format.json { 
          if error
            render json: {error: error}
          else
            if user.designer
              render json: {username:    user.designer_profile.full_name,
                          keywords:    user.default_keywords,
                          audience:    user.default_target_audience,
                          email:       user.email,
                          company:     user.company,
                          id:          user.id.to_s}
            else
              
              render json: {username:    user.full_name,
                          keywords:    user.default_keywords,
                          audience:    user.default_target_audience,
                          email:       user.email,
                          company:     user.company,
                          id:          user.id.to_s}
            end
          end }
    end
  end

  def sign_up
    existing_user = User.where(email: params[:email]).first
    if !existing_user 
        @user = User.new({email:      params[:email],
                          name:       params[:name],
                          password:   params[:password],
                          company:    params[:company]})
        @user.save

        sign_in  @user
        sign_in  @user, :bypass => true
        save_login(params[:email])
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
