class ContractsController < ApplicationController
#  include AwsRobot

  before_action :set_contract, only: [:show, :edit, :update, :destroy!]

  # GET /contracts
  # GET /contracts.json
  def index
    @contracts = Contract.all
  end

  # GET /contracts/1
  # GET /contracts/1.json
  def show
  end

  # GET /contracts/new
  def new
    @contract = Contract.new
  end

  # GET /contracts/1/edit
  def edit
  end

  # POST /contracts
  def create
    params[:contract][:name] = @contract.smash_client.name
    @contract = Contract.new(contract_params)
    respond_to do |format|
      if @contract.save!
        format.html { redirect_to @contract, notice: 'Contract was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /contracts/1
  def update
    respond_to do |format|
      if @contract.update(contract_params)
        format.html { redirect_to @contract, notice: 'Instance was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @contract.destroy!
    respond_to do |format|
      #format.html { redirect_to contracts_url, notice: 'Contract was successfully destroyed.' }
      format.html { redirect_to smash_clients_url, notice: 'Instance was successfully destroyed.' }
    end
  end

  def stop_instance
    contract = Contract.find( params[:id] )
    if (contract.current_state < :deleted) && contract.stop!
      @smash_client = contract.smash_client
      @smash_clients = SmashClient.where( user: current_user.user_name )
      render "smash_clients/index"
      #format.html { redirect_to :root, notice: 'Successfully stoped the instance' }
    else
      render "smash_clients/index"
      #format.html { redirect_to :root, notice: 'Something went wrong stopping the instance' }
    end
  end

  def terminate_instance
    contract = Contract.find( params[:id] )
    if contract.terminate!
      logger.info 'Successfully terminated your instance'
    else
      logger.info 'There was a problem terminating your instance'
    end
  end

  def instance_status
    status = @contract.status
  end

  private
    def set_contract
      @contract = Contract.find(params[:id])
    end

    def contract_params
      params.require(:contract).permit(:name, :instance_id, :smash_client_id, :instance_type)
    end
end
