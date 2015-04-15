class SmashClient < ActiveRecord::Base
  has_many :contracts, dependent: :destroy
  accepts_nested_attributes_for :contracts, allow_destroy: true#, 
#    reject_if: lambda { |attributes| attributes[:instance_type].blank? }

  def make_instance
#    self.contracts.create!( name: self.name )
  end

  def make_spot_instance
    self.contracts.create_spot!( name: self.name )
  end

  # configures Aws and creates an EC2 object -> @ec2
  def aws_client
    config = YAML.load( File.open( File.expand_path( File.join( Rails.root, 'config/connection_config.yml' ))))[self.user.to_sym]
    creds = Aws::Credentials.new( config[:access_key_id], config[:secret_access_key] )
    @client ||= Aws::EC2::Client.new( credentials: creds, region: config[:regions].first )
  end  # end connect
end
# smash_client makes bids happen, security, memory allocation, instance types etc.
# bids take care of the ami copy and whatever else needs to happen for a bid to take place.
