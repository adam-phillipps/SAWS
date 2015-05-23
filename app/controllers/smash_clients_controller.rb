class SmashClientsController < ApplicationController
  before_action :set_smash_client, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  def index
    if user_signed_in?
      @smash_client
      @smash_clients = SmashClient.where( user: current_user.user_name )
    else
      redirect_to users_path
    end
  end

  def show
  end

  def new
    @smash_client = SmashClient.new
    @smash_client.contracts.build
  end

  def edit
  end

  def add_contract
    @smash_client.contracts.build
  end

  def create
    params[:smash_client][:user] = current_user.user_name
    @smash_client = SmashClient.create( smash_client_params )
    if @smash_client.save!
      redirect_to @smash_client, notice: "Smash client created."
    else
      format.html { render :new, error: 'Error creating smash client.' }
    end
  end

  def update
    respond_to do |format|
      if @smash_client.update(smash_client_params)
        format.html { redirect_to @smash_client, notice: 'Smash client was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    smash_client = SmashClient.find( params[:id] )
    if smash_client.destroy!
      flash[:notice] = "Successfully destroyed client: #{smash_client.id}"
    else
      flash[:error] = "There was a problem destroying client: #{smash_client.id}"
    end
  end

  private
    def set_smash_client
      @smash_client = SmashClient.find(params[:id])
    end

    def smash_client_params
      @smash_client_params = params.require(:smash_client).
        permit( :user, :name, contracts_attributes: [:id, :name, :smash_client_id, :instance_type])
    end
end
