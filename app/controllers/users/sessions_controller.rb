class Users::SessionsController < Devise::SessionsController
# before_filter :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
   def new
    byebug
  #   super
   end

  # POST /resource/sign_in
   def create
  #   super
    byebug
    @user = User.new(user_params)

    respond_to do |format|
      if @user.save!
        format.html { redirect_to @user, notice: 'User was successfully created.' }
      else
        format.html { render :new }
      end
    end
   end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # You can put the params you want to permit in the empty array.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.for(:sign_in) << :attribute
  # end
end
