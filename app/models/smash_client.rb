class SmashClient < ActiveRecord::Base
  has_many :contracts
  attr_accessor :contract

  def make_instance
    connect
    @contract = Contract.new( {smash_client_id: self.id, name: self.name} )
    @instance =  @contract.make_it( @ec2, self.name ) if @contract.save!
  end

  # configures Aws and creates an EC2 object -> @ec2
  def connect()
    config = YAML.load( File.open( File.expand_path( File.join( Rails.root, 'config/connection_config.yml' ))))[self.user.to_sym]
    creds = Aws::Credentials.new( config[:access_key_id], config[:secret_access_key] )
    @ec2 = Aws::EC2::Client.new( credentials: creds, region: config[:regions].first )
  end  # end connect

  def stop_instances( params={} )
    byebug
    contract = params[:contract]
#    contract = Contract.where(smash_client_id: self.id, name: self.name).first
    contract.stop_instances
  end
end
# smash_client makes bids happen, security, memory allocation, instance types etc.
# bids take care of the ami copy and whatever else needs to happen for a bid to take place.
