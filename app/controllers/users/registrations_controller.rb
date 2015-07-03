class Users::RegistrationsController < Devise::RegistrationsController
# before_filter :configure_sign_up_params, only: [:create]
# before_filter :configure_account_update_params, only: [:update]
  skip_before_filter :require_no_authentication

  # GET /resource/sign_up
   def new
     super
   end

  # POST /resource
  def create
    if params[:user][:admin].eql? 'true'
      params[:user][:admin] = true
    elsif params[:user][:admin].eql? 'false'
      params[:user][:admin] = false
    end
#    params[:user][:admin] = value_to_bool(params[:user][:admin])
    build_resource(sign_up_params)

    resource.save
    yield resource if block_given?
    if resource.persisted?
      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_flashing_format?
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_flashing_format?
        expire_data_after_sign_in!
      end
    else
      clean_up_passwords resource
      set_minimum_password_length
    end
    respond_with current_user, location: root_path
  end

  # GET /resource/edit
  def edit
    super
  end

def set_minimum_password_length
  if devise_mapping.validatable?
    @minimum_password_length = resource_class.password_length.min
  end
end

  # PUT /resource
  # def update
  #   super
  # end

  # DELETE /resource
  # def destroy
  #   super
  # end

  # GET /resource/cancel
  # Forces the session data which is usually expired after sign
  # in to be expired now. This is useful if the user wants to
  # cancel oauth signing in/up in the middle of the process,
  # removing all OAuth session data.
  # def cancel
  #   super
  # end

  # protected

  # You can put the params you want to permit in the empty array.
  # def configure_sign_up_params
  #   devise_parameter_sanitizer.for(:sign_up) << :attribute
  # end

  # You can put the params you want to permit in the empty array.
  # def configure_account_update_params
  #   devise_parameter_sanitizer.for(:account_update) << :attribute
  # end

  # The path used after sign up.
  # def after_sign_up_path_for(resource)
  #   super(resource)
  # end

  # The path used after sign up for inactive accounts.
  # def after_inactive_sign_up_path_for(resource)
  #   super(resource)
  # end
end
