class SmashClientsController < ApplicationController
  before_action :set_smash_client, only: [:show, :edit, :update, :destroy]
  before_action :authenticate_user!

  # GET /smash_clients
  # GET /smash_clients.json
  def index
    if user_signed_in?
      @smash_client
      @smash_clients = SmashClient.where( user: current_user.user_name )
    else
      redirect_to users_path
    end
  end

  # GET /smash_clients/1
  # GET /smash_clients/1.json
  def show

  end

  # GET /smash_clients/new
  def new
    @smash_client = SmashClient.new
    @smash_client.contracts.build
  end

  # GET /smash_clients/1/edit
  def edit
  end

  def add_contract
    @smash_client.contracts.build
  end

  # POST /smash_clients
  # POST /smash_clients.json
  def create
    params[:smash_client][:user] = current_user.user_name
    @smash_client = SmashClient.create!( smash_client_params )
    if @smash_client.save
      redirect_to @smash_client, notice: "Smash client created."
    else
      format.html { render :new, error: 'Error creating smash client.' }
    end
  end

  # PATCH/PUT /smash_clients/1
  # PATCH/PUT /smash_clients/1.json
  def update
    respond_to do |format|
      if @smash_client.update(smash_client_params)
        format.html { redirect_to @smash_client, notice: 'Smash client was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /smash_clients/1
  # DELETE /smash_clients/1.json
  def destroy
    # assumes killing a parent instance will kill all related instances
    if params[:kill_type].eql? 'stop'
      stop
    else
      terminate
    end
  end

  def stop
    # assumes killing a parent instance will kill all related instances
    smash_client = SmashClient.find(params[:id])
    contract = smash_client.contracts.first
    if contract.stop
      if smash_client.destroy
        flash[:notice] = "Your instance stopped successfully!"
      else
        flash[:error] = "Error stopping your instance"
      end
    end
    redirect_to smash_clients_url
  end

  def terminate
    # assumes killing a parent instance will kill all related instances
    smash_client = SmashClient.find(params[:id])
    contract = smash_client.contracts.first
    if contract.terminate_instances
      if smash_client.destroy
        flash[:notice] = "Your instance terminated successfully!"
      else
        flash[:error] = "Error terminated your instance"
      end
    end
    redirect_to smash_clients_url
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_smash_client
      @smash_client = SmashClient.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def smash_client_params
      @smash_client_params = params.require(:smash_client).
        permit( :user, :name, contracts_attributes: [:id, :name, :smash_client_id, :instance_type])
    end
end
