class SmashClientsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_smash_client, only: [:index, :new, :update, :create_spot]#, :new]

  # GET /smash_clients
  # GET /smash_clients.json
  def index
    @smash_clients = SmashClient.where(user: current_user[:email])
    unless @smash_clients.count > 0

    end
    @smash_clients
#    @smash_clients = sc.count.eql? 0 ?  (render :new) : sc
  end

  # GET /smash_clients/1
  # GET /smash_clients/1.json
  def show
    render :index
  end

  # GET /smash_clients/new
  def new
    byebug
    unless !user_signed_in?
      @smash_client = SmashClient.new(params[:smash_client])
      if @smash_client.save!
        redirect_to smash_clients_path, notice: "new client created: #{@smash_client.name}\n"
      else
        render :new_user_session
      end
    end
  end

  # GET /smash_clients/1/edit
  def edit
    puts "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&\nhere here here here"
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
    byebug
    @smash_client = SmashClient.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def smash_client_params
    params.require(:smash_client).permit(:name, :user)
  end

  def create_spot
    {name: 'you created something here, you really did'}
  end
end
