class SmashClientsController < ApplicationController
  before_filter :authenticate_user!
  before_action :set_smash_client, only: [:show, :edit, :update, :destroy]

  # GET /smash_clients
  # GET /smash_clients.json
  def index
    @smash_clients = SmashClient.all
  end

  # GET /smash_clients/1
  # GET /smash_clients/1.json
  def show
  end

  # GET /smash_clients/new
  def new
    @smash_client = SmashClient.new
  end

  # GET /smash_clients/1/edit
  def edit
  end

  # POST /smash_clients
  # POST /smash_clients.json
  def create
    @smash_client = SmashClient.new(smash_client_params)

    respond_to do |format|
      if @smash_client.save
        format.html { redirect_to @smash_client, notice: 'Smash client was successfully created.' }
        format.json { render :show, status: :created, location: @smash_client }
      else
        format.html { render :new }
        format.json { render json: @smash_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /smash_clients/1
  # PATCH/PUT /smash_clients/1.json
  def update
    respond_to do |format|
      if @smash_client.update(smash_client_params)
        format.html { redirect_to @smash_client, notice: 'Smash client was successfully updated.' }
        format.json { render :show, status: :ok, location: @smash_client }
      else
        format.html { render :edit }
        format.json { render json: @smash_client.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /smash_clients/1
  # DELETE /smash_clients/1.json
  def destroy
    @smash_client.destroy
    respond_to do |format|
      format.html { redirect_to smash_clients_url, notice: 'Smash client was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_smash_client
      @smash_client = SmashClient.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def smash_client_params
      params.require(:smash_client).permit(:name, :user)
    end
end
